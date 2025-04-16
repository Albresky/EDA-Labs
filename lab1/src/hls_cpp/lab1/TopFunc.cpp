/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved.
 *
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-03-18 19:10:53
 * @LastEditTime: 2025-04-16 20:39:44
 * @FilePath: /BUPT-EDA-Labs/lab1/src/TopFunc.cpp
 *
 * @Description: Top Function
 */
#include "TopFunc.h"
#include <fstream>

using namespace std;

// ofstream log_file("log.txt");

// 相位误差计算
float PhaseDetector(float I, float Q) {# 文件名设置
  TOP_MODULE = TopFunc_tb
  SRC_FILES = TopFunc_tb.v TopFunc.v Modulator.v DownConvert.v Integrator.v Detector.v GenerateMCode.v
  VCD_FILE = $(TOP_MODULE).vcd
  
  # 仿真目标
  all: run
  
  # 编译
  compile:
    iverilog -o $(TOP_MODULE).out $(SRC_FILES)
  
  # 运行
  run: compile
    vvp $(TOP_MODULE).out
  
  # 打开波形
  wave:
    gtkwave $(VCD_FILE)
  
  # 清理中间文件
  clean:
    rm -f *.out *.vcd
  
  return (I > 0 ? Q : -Q);
}

// 相位累加器增加相位调整
void LocalCarrier(ap_uint<32> &phase_acc, float phi_est, float &cos_out,
                  float &sin_out) {
#pragma HLS inline off
  // phase_acc 充当采样序列标号 n 的计数
  float phase = 1.0 * PHASE_INC * phase_acc + phi_est; // 相位估计值 phi_est

  cos_out = hls::cosf(phase);
  sin_out = hls::sinf(phase);
  phase_acc++;
}

// m 码生成器（31 位）
ap_uint<1> GenerateMCode(ap_uint<5> &state) {
#pragma HLS inline
  ap_uint<1> feedback = state[4] ^ state[2]; // 反馈多项式： x^5 + x^3 +1
  state = (state << 1) | feedback;
  return state[0]; // 输出最低位
}

// 码相位控制器
void CodeController(bool sync_flag, ap_uint<5> &m_state) {
#pragma HLS inline
  if (!sync_flag) {
    m_state = (m_state >> 1) | (m_state[0] << 4); // 循环右移
  } else {
    std::cout << "Sync achieved!" << std::endl;
  }
}

// 下变频：与相关操作
void DownConvert(sample_t if_in, float cos_phase, float sin_phase,
                 ap_uint<1> m_code, float &I_out, float &Q_out) {
#pragma HLS inline off
  // 2 位补码转浮点（11:-1, 10:-2, 00:0, 01:+1）
  float if_float;
  switch (if_in) {
  case 0b11:
    if_float = -1.0;
    break;
  case 0b10:
    if_float = -0.5;
    break;
  case 0b00:
    if_float = 0.5;
    break;
  default:
    if_float = 0.0; // 01
  }

  // 下变频
  I_out = if_float * cos_phase * (m_code ? 1.0 : -1.0);
  Q_out = if_float * sin_phase * (m_code ? 1.0 : -1.0);
}

// 积分器
void Integrator(float &I_in, float &Q_in, float &I_sum, float &Q_sum,
                ap_uint<16> &sample_count, ap_uint<1> &integral_done) {
#pragma HLS INLINE
  I_sum += I_in;
  Q_sum += Q_in;

  if (++sample_count >=
      SAMPLES_PER_CHIP * CODE_LENGTH) { // 31 位码片 * 16 = 496
    integral_done = true;
    sample_count = 0;
  } else {
    integral_done = false;
  }
}

// 能量计算与同步判断
void EnergyCalc(float I_sum, float Q_sum, ap_uint<1> &sync_flag,
                float &max_energy) {
#pragma HLS inline off
  float S = I_sum * I_sum + Q_sum * Q_sum;
  sync_flag = (S > THRESHOLD);

  if (S > max_energy) {
    max_energy = S;
  }

//   log_file << "Energy: " << S << ", max_energy: " << max_energy
//             << ", Sync: " << sync_flag << std::endl;

//   if (sync_flag) {
//     log_file << "Synchronization achieved, I_sum: " << I_sum
//               << ", Q_sum: " << Q_sum << std::endl;
//   }
}

sample_t QuantizeSample(float value) {
  if (value >= 0.5)
    return 0b00;
  else if (value >= 0)
    return 0b01; // +1
  else if (value >= -0.5)
    return 0b10; // -2
  else if (value >= -1)
    return 0b11; // -1
  else
    return 0b00; // 0
}

// 发送端 m 序列生成器, 与接收端一致
ap_uint<1> GenerateTxMCode(ap_uint<5> &state) {
#pragma HLS inline off
  ap_uint<1> feedback = state[4] ^ state[2];
  state = (state << 1) | feedback;
  return state[0];
}

// IFin 信号生成器
sample_t GenerateIFSignal(ap_uint<1> data_bit, ap_uint<5> &tx_m_state,
                          int sample_idx) {
#pragma HLS inline off
  // 数据位持续时间: 1ms, 496 样点
  static int data_counter = 0;
  static ap_uint<1> current_data = 0;
  static ap_uint<1> current_code = 0;

  // 每 1ms 更新数据位
  if (data_counter >= SAMPLES_PER_MS) {
    current_data = data_bit;
    data_counter = 0;
  }
  data_counter++;

  // 生成码片（31 码片/ms，每个码片 16 样点）
  int chip_idx = sample_idx % 16;
  if (chip_idx == 0) {
    ap_uint<1> m_code = GenerateTxMCode(tx_m_state);
    current_code = m_code;
  }

  // 调制：D⊕M 后，输入极化函数
  ap_uint<1> xor_bit = current_data ^ current_code;
  float symbol = (xor_bit ? 1.0f : -1.0f);

  // 载波调制
  float phase = 2 * M_PI * CARRIER_FREQ * sample_idx / SAMPLE_RATE;
  float if_signal = symbol * cos(phase);

  // 量化: 加入噪声模拟实际 ADC
  // if_signal += 0.1 * (rand() / (float)RAND_MAX - 0.5); // 5% 噪声
  return QuantizeSample(if_signal);
}

void transmitter_wrapper(ap_uint<5> tx_m_state,
                         ap_uint<DATA_LEN> &test_data,
                         ap_uint<1> &sync_flag_out,
                         hls::stream<ap_uint<1>> &sync_flag_in_strm,
                         hls::stream<ap_uint<1>> &end_flag_out_strm,
                         hls::stream<sample_t> &if_signal_out_strm) {
#pragma HLS inline off
  sample_t if_in;
  float phase_est_value = 0.0;

  ap_uint<1> sync_flag = false;
  ap_uint<1> end_flag = false;
  DemodData demod_values;
  demod_values.I = 0.0;
  demod_values.Q = 0.0;

  int t = 0;
  while (!end_flag && t < SIM_TIME_MS * SAMPLES_PER_MS) {
    // 检测同步
    if (!sync_flag_in_strm.empty()) {
      sync_flag = sync_flag_in_strm.read();
      if (sync_flag) {
        end_flag = true;
        end_flag_out_strm.write(ap_uint<1>(end_flag));
      }
    } else {
      // 生成发送端 IF 信号
      int data_idx = (t++ / SAMPLES_PER_MS) % DATA_LEN;
      ap_uint<1> data_bit = test_data[data_idx];
      if_in = GenerateIFSignal(data_bit, tx_m_state, t);

      if_signal_out_strm.write(if_in);
      end_flag_out_strm.write(ap_uint<1>(end_flag));
    }
  }

  if (!sync_flag) {
    end_flag = true;
    end_flag_out_strm.write(ap_uint<1>(end_flag));
  }

  sync_flag_out = sync_flag;
}

void receiver_wrapper(ap_uint<5> rx_m_state,
                      hls::stream<sample_t> &if_signal_in_strm,
                      hls::stream<ap_uint<1>> &end_flag_in_strm,
                      hls::stream<ap_uint<1>> &sync_flag_out_strm) {
#pragma HLS inline off
  float I_accum = 0, Q_accum = 0; // I/Q 路积分初值
  float phi_est = 0.0;            // 初始相位
  float max_energy = 0.0;         // 最大能量
  float cos_wave, sin_wave;       // 本地载波
  float I = 0.0, Q = 0.0;         // I/Q 路下变频信号

  ap_uint<1> sync_flag = false;     // 同步标志
  ap_uint<1> end_flag = false;      // 样本结束标志
  ap_uint<1> integral_done = false; // 积分完成标志
  ap_uint<5> m_state = rx_m_state;  // 接收端 m 码初始状态
  ap_uint<16> sample_count = 0;     // 积分计数器
  ap_uint<32> phase_acc = 0;        // 相位累加器
  sample_t if_in;                   // 输入 IF 信号

  // sync_flag_out_strm.write(sync_flag);
  while (!end_flag) {
    // if(end_flag_in_strm.empty()) continue;
    end_flag = end_flag_in_strm.read();
    if (end_flag) {
      break;
    }
    if_in = if_signal_in_strm.read();

    // 生成本地载波
    LocalCarrier(phase_acc, phi_est, cos_wave, sin_wave);

    // 生成 m 序列
    ap_uint<1> m_code = GenerateMCode(m_state);

    // 下变频与相关
    DownConvert(if_in, cos_wave, sin_wave, m_code, I, Q);

    // 积分
    Integrator(I, Q, I_accum, Q_accum, sample_count, integral_done);

    // 能量计算与同步判断
    if (integral_done) {
      EnergyCalc(I_accum, Q_accum, sync_flag, max_energy);

      sync_flag_out_strm.write(sync_flag);

      // 相位跟踪
      float phi_error = PhaseDetector(I_accum, Q_accum);
      phi_est += KP_GAIN * phi_error;
      I_accum = Q_accum = 0;

      // 码相位控制
      CodeController(sync_flag, m_state);

      if (sync_flag) {
        rx_m_state = m_state;
        phase_acc = 0;
        sample_count = 0;
      }
    }
  }
}

void TopFunc(ap_uint<DATA_LEN> test_data, ap_uint<5> tx_m_state,
             ap_uint<5> rx_m_state, ap_uint<1> &sync_flag) {
#pragma HLS dataflow

  hls::stream<ap_uint<1>> sync_flag_strm("sync_flag_strm");
#pragma HLS stream variable = sync_flag_strm type = fifo depth = 8192

  hls::stream<ap_uint<1>> end_flag_strm("end_flag_strm");
#pragma HLS stream variable = end_flag_strm type = fifo depth = 8192

  hls::stream<sample_t> if_signal_strm("if_signal_strm");
#pragma HLS stream variable = if_signal_strm type = fifo depth = 8192

  transmitter_wrapper(tx_m_state, test_data, sync_flag,
                      sync_flag_strm, end_flag_strm, if_signal_strm);
  receiver_wrapper(rx_m_state, if_signal_strm, end_flag_strm, sync_flag_strm);
}