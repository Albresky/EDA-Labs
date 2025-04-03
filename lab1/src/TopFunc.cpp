/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved.
 *
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-03-18 19:10:53
 * @LastEditTime: 2025-04-03 14:30:17
 * @FilePath: /BUPT-EDA-Labs/lab1/src/TopFunc.cpp
 *
 * @Description: Top Function
 */
#include "TopFunc.h"

// 相位误差计算
void PhaseDetector(hls::stream<DemodData> &input_stream,
                   hls::stream<float> &phase_error_stream) {
#pragma HLS PIPELINE II = 1
#pragma HLS INTERFACE mode = ap_ctrl_hs port = return

  DemodData demod = input_stream.read();
  float phase_error = (demod.I > 0) ? demod.Q : -demod.Q;
  phase_error_stream.write(phase_error);
}

// 相位累加器增加相位调整
void LocalCarrier(hls::stream<ap_uint<32>> &phase_acc_in,
                  hls::stream<ap_uint<32>> &phase_acc_out,
                  hls::stream<float> &phi_est,
                  hls::stream<PhaseData> &out_stream) {
#pragma HLS PIPELINE II = 1
#pragma HLS INTERFACE mode = ap_ctrl_hs port = return

  // phase_acc 充当采样序列标号 n 的计数
  ap_uint<32> phase_acc = phase_acc_in.read();
  float phase_adjustment = phi_est.read();

  // 相位估计值 phi_est
  float phase = 1.0f * PHASE_INC * phase_acc + phase_adjustment;

  PhaseData phase_data;
  phase_data.cos_wave = hls::cosf(phase);
  phase_data.sin_wave = hls::sinf(phase);

  out_stream.write(phase_data);
  phase_acc_out.write(phase_acc + 1);
}

// m 码生成器（31 位）
void GenerateMCode(hls::stream<ap_uint<5>> &state_in,
                   hls::stream<ap_uint<5>> &state_out,
                   hls::stream<ap_uint<1>> &code_out) {
#pragma HLS PIPELINE II = 1
#pragma HLS INTERFACE mode = ap_ctrl_hs port = return

  ap_uint<5> state = state_in.read();
  ap_uint<1> feedback = state[4] ^ state[2]; // 反馈多项式： x^5 + x^3 +1
  state = (state << 1) | feedback;
  state_out.write(state);   // Update state
  code_out.write(state[0]); // 输出最低位 LSB
}

// 码相位控制器
void CodeController(hls::stream<SyncData> &sync_stream,
                    hls::stream<ap_uint<5>> &m_state_in,
                    hls::stream<ap_uint<5>> &m_state_out) {
#pragma HLS PIPELINE II = 1
#pragma HLS INTERFACE mode = ap_ctrl_hs port = return

  SyncData sync_data = sync_stream.read();
  ap_uint<5> m_state = m_state_in.read();

  if (!sync_data.sync_flag) {
    // 循环右移
    m_state = (m_state >> 1) | (m_state[0] << 4);
  } else {
    std::cout << "Sync achieved!" << std::endl;
  }

  m_state_out.write(m_state);
}

// 下变频：与相关操作
void DownConvert(hls::stream<sample_t> &if_in,
                 hls::stream<PhaseData> &carrier_stream,
                 hls::stream<ap_uint<1>> &m_code,
                 hls::stream<DemodData> &out_stream) {
#pragma HLS PIPELINE II = 1
#pragma HLS INTERFACE mode = ap_ctrl_hs port = return

  sample_t if_sample = if_in.read();
  PhaseData carrier = carrier_stream.read();
  ap_uint<1> code_bit = m_code.read();

  // 2 位补码转浮点（11:-1, 10:-2, 00:0, 01:+1）
  float if_float;
  switch (if_sample) {
  case 0b11:
    if_float = -1.0f;
    break;
  case 0b10:
    if_float = -2.0f;
    break;
  case 0b00:
    if_float = 0.0f;
    break;
  default:
    if_float = 1.0f; // 01
  }

  // 下变频与相关
  DemodData demod;
  demod.I = if_float * carrier.cos_wave * (code_bit ? 1.0f : -1.0f);
  demod.Q = if_float * carrier.sin_wave * (code_bit ? 1.0f : -1.0f);

  out_stream.write(demod);
}

// 积分器
void Integrator(hls::stream<DemodData> &in_stream,
                hls::stream<IntegralData> &out_stream,
                hls::stream<ap_uint<16>> &sample_count_in,
                hls::stream<ap_uint<16>> &sample_count_out) {
#pragma HLS PIPELINE II = 1
#pragma HLS INTERFACE mode = ap_ctrl_hs port = return

  static float I_sum = 0.0f, Q_sum = 0.0f;
  DemodData demod = in_stream.read();
  ap_uint<16> sample_count = sample_count_in.read();

  // 累加 I 和 Q 分量
  I_sum += demod.I;
  Q_sum += demod.Q;

  IntegralData integral;
  integral.I_sum = I_sum;
  integral.Q_sum = Q_sum;

  sample_count++;
  if (sample_count >= SAMPLES_PER_CHIP * CODE_LENGTH) { // 31 位码片 * 16 = 496
    integral.integral_done = true;
    sample_count = 0;
    I_sum = 0.0f;
    Q_sum = 0.0f;
  } else {
    integral.integral_done = false;
  }

  out_stream.write(integral);
  sample_count_out.write(sample_count);
}

// 能量计算与同步判断
void EnergyCalc(hls::stream<IntegralData> &in_stream,
                hls::stream<SyncData> &out_stream,
                hls::stream<float> &max_energy_in,
                hls::stream<float> &max_energy_out) {
#pragma HLS PIPELINE II = 1
#pragma HLS INTERFACE mode = ap_ctrl_hs port = return

  IntegralData integral = in_stream.read();
  float max_energy = max_energy_in.read();

  SyncData sync_data;

  if (integral.integral_done) {
    float energy =
        integral.I_sum * integral.I_sum + integral.Q_sum * integral.Q_sum;
    sync_data.sync_flag = (energy > THRESHOLD);

    if (energy > max_energy) {
      max_energy = energy;
    }

    std::cout << "Energy: " << energy << ", max_energy: " << max_energy
              << ", Sync: " << sync_data.sync_flag << std::endl;

    if (sync_data.sync_flag) {
      std::cout << "Synchronization achieved, I_sum: " << integral.I_sum
                << ", Q_sum: " << integral.Q_sum << std::endl;
    }

    sync_data.phase_error =
        (integral.I_sum > 0) ? integral.Q_sum : -integral.Q_sum;
  } else {
    // Pass through previous sync flag for non-integration samples
    sync_data.sync_flag = false;
    sync_data.phase_error = 0.0f;
  }

  out_stream.write(sync_data);
  max_energy_out.write(max_energy);
}

// 顶层模块
void SignalSync(hls::stream<sample_t> &if_in, hls::stream<bool> &sync_flag_out,
                hls::stream<ap_uint<1>> &m_code_out,
                hls::stream<ap_uint<5>> &m_state_out,
                hls::stream<ap_uint<32>> &phase_acc_out,
                hls::stream<DemodData> &demod_out,
                hls::stream<float> &phi_est_out) {
#pragma HLS DATAFLOW
#pragma HLS INTERFACE mode = ap_ctrl_hs port = return

  static hls::stream<ap_uint<5>, STREAM_DEPTH> m_state_stream("m_state");
  static hls::stream<ap_uint<1>, STREAM_DEPTH> m_code_stream("m_code");
  static hls::stream<PhaseData, STREAM_DEPTH> carrier_stream("carrier");
  static hls::stream<ap_uint<32>, STREAM_DEPTH> phase_acc_stream("phase_acc");
  static hls::stream<DemodData, STREAM_DEPTH> demod_stream("demod");
  static hls::stream<IntegralData, STREAM_DEPTH> integral_stream("integral");
  static hls::stream<SyncData, STREAM_DEPTH> sync_stream("sync");
  static hls::stream<float, STREAM_DEPTH> phase_error_stream("phase_error");
  static hls::stream<ap_uint<16>, STREAM_DEPTH> sample_count_stream(
      "sample_count");
  static hls::stream<float, STREAM_DEPTH> max_energy_stream("max_energy");
  static hls::stream<float, STREAM_DEPTH> phi_est_stream("phi_est");

  static ap_uint<5> m_state = 0b10101; // 初始 m 序列
  static ap_uint<32> phase_acc = 0;    // 相位累加器
  static float phi_est = 0.0f;         // 初始相位预估值
  static ap_uint<16> sample_count = 0; // 积分过程的累加计数器
  static float max_energy = 0.0f;      // 最大能量
  static bool sync_flag = false;       // 信号同步 flag
  static ap_uint<1> m_code = 0;        // m 码

  m_state_stream.write(m_state);
  phase_acc_stream.write(phase_acc);
  phi_est_stream.write(phi_est);
  sample_count_stream.write(sample_count);
  max_energy_stream.write(max_energy);

  // 生成 m 序列
  GenerateMCode(m_state_stream, m_state_stream, m_code_stream);

  m_code = m_code_stream.read();
  m_code_out.write(m_code);
  m_code_stream.write(m_code);

  // 生成本地载波
  LocalCarrier(phase_acc_stream, phase_acc_stream, phi_est_stream,
               carrier_stream);

  // 下变频, 与相关
  DownConvert(if_in, carrier_stream, m_code_stream, demod_stream);

  DemodData demod = demod_stream.read();
  demod_out.write(demod);
  demod_stream.write(demod);

  // I, Q 变量的积分
  Integrator(demod_stream, integral_stream, sample_count_stream,
             sample_count_stream);

  // 能量计算与同步判断
  EnergyCalc(integral_stream, sync_stream, max_energy_stream,
             max_energy_stream);

  SyncData sync_data = sync_stream.read();
  sync_flag = sync_data.sync_flag;
  sync_flag_out.write(sync_flag);

  // 相位跟踪
  if (sync_data.sync_flag) {
    phi_est += KP_GAIN * sync_data.phase_error;
  }
  phi_est_out.write(phi_est);

  m_state_stream.write(m_state);
  sync_stream.write(sync_data);

  // 码相位控制
  CodeController(sync_stream, m_state_stream, m_state_stream);

  m_state = m_state_stream.read();
  phase_acc = phase_acc_stream.read();
  sample_count = sample_count_stream.read();
  max_energy = max_energy_stream.read();

  m_state_out.write(m_state);
  phase_acc_out.write(phase_acc);
}