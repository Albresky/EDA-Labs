/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved.
 *
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-03-18 19:10:53
 * @LastEditTime: 2025-03-25 19:55:11
 * @FilePath: /BUPT-EDA-Labs/lab1/src/TopFunc.hpp
 *
 * @Description: Top Function
 */
#include <ap_int.h>
#include <hls_math.h>

// 定义常量和类型
#define CARRIER_FREQ 124000                        // 124kHz 载波
#define SAMPLE_RATE (4 * CARRIER_FREQ)             // 496kHz 采样率
#define CODE_LENGTH 31                             // m 码长度
#define CHIP_RATE 31000                            // 31kHz 码片速率
#define SAMPLES_PER_CHIP (SAMPLE_RATE / CHIP_RATE) // 16 采样/码片
#define INTEGRAL_TIME 1                            // 1ms 积分时间 Ts
#define THRESHOLD 0.25                              // 能量阈值
#define KP_GAIN 0.01                               // 环路增益

typedef ap_int<2> sample_t; // 2位补码输入

// 相位误差计算
float PhaseDetector(float I, float Q) {
    // 例如：Q支路符号判决误差
    return (I > 0 ? Q : -Q); 
}

// 相位累加器增加相位调整
void LocalCarrier(ap_uint<32> &phase_acc, float phi_est, float &cos_out, float &sin_out) {
    const float PHASE_INC = 2.0 * M_PI * CARRIER_FREQ / SAMPLE_RATE;
    float phase = PHASE_INC * phase_acc + phi_est; // 加入相位估计值
    cos_out = hls::cosf(phase);
    sin_out = hls::sinf(phase);
    phase_acc++;
}

// m 码生成器（31位LFSR）
ap_uint<1> GenerateMCode(ap_uint<5> &state) {
#pragma HLS INLINE
  ap_uint<1> feedback = state[4] ^ state[2]; // 正确反馈多项式 x^5 + x^3 +1
  state = (state << 1) | feedback;
  return state[0]; // 输出最低位
}

// 码相位控制器
void CodeController(bool sync_flag, ap_uint<5> &m_state,
                    ap_uint<5> &shift_counter) {
#pragma HLS INLINE
  if (!sync_flag) {
    if (++shift_counter >= CODE_LENGTH) {
      m_state = (m_state >> 1) | (m_state[0] << 4); // 循环右移
      shift_counter = 0;
    }
  }else{
    std::cout << "Sync achieved!" << std::endl;
  }
}

// 下变频：与相关操作
void DownConvert(sample_t if_in, float cos_phase, float sin_phase,
                 ap_uint<1> m_code, float &I_out, float &Q_out) {
#pragma HLS INLINE
  // 2位补码转浮点（11:-1, 10:-2, 00:0, 01:+1）
  float if_float;
  switch (if_in) {
  case 0b11:
    if_float = -1.0;
    break;
  case 0b10:
    if_float = -2.0;
    break;
  case 0b00:
    if_float = 0.0;
    break;
  default:
    if_float = 1.0; // 01
  }

  // 下变频
  I_out = if_float * cos_phase * (m_code ? 1.0 : -1.0);
  Q_out = if_float * sin_phase * (m_code ? 1.0 : -1.0);
}

// 积分器
void Integrator(float I_in, float Q_in, float &I_sum, float &Q_sum,
                ap_uint<16> &sample_count, bool &integral_done) {
#pragma HLS INLINE
  I_sum += I_in;
  Q_sum += Q_in;

  if (++sample_count >= SAMPLES_PER_CHIP * CODE_LENGTH) { // 31码片*16=496
    integral_done = true;
    sample_count = 0;
  } else {
    integral_done = false;
  }
}

// 能量计算与同步判断
void EnergyCalc(float I_sum, float Q_sum, bool &sync_flag) {
#pragma HLS INLINE
  float S = I_sum * I_sum + Q_sum * Q_sum;
  std::cout << "Energy: " << S << std::endl;
  sync_flag = (S > THRESHOLD);
}

// 顶层模块
void SpreadSpectrumSync(sample_t if_in, bool &sync_flag, ap_uint<1> &m_code_out,
                        ap_uint<5> &m_state, ap_uint<32> &phase_acc) {
#pragma HLS INTERFACE ap_ctrl_none port = return
#pragma HLS PIPELINE II = 1

  // 静态变量保存状态
  static float I_accum = 0, Q_accum = 0;
  static ap_uint<16> sample_count = 0;
  static ap_uint<5> shift_counter = 0;
  static bool int_done = false;
  static float phi_est = 0.0; // 初始相位

  // 生成本地载波
  float cos_wave, sin_wave;
  LocalCarrier(phase_acc, phi_est, cos_wave, sin_wave);

  // 生成m序列
  ap_uint<1> m_code = GenerateMCode(m_state);
  m_code_out = m_code;

  // 下变频与相关
  float I, Q;
  DownConvert(if_in, cos_wave, sin_wave, m_code, I, Q);

  // 积分
  Integrator(I, Q, I_accum, Q_accum, sample_count, int_done);

  // 能量计算与同步判断
  if (int_done) {
    EnergyCalc(I_accum, Q_accum, sync_flag);
    // 相位跟踪
    float phi_error = PhaseDetector(I_accum, Q_accum);
    phi_est += KP_GAIN * phi_error; // Kp为环路增益
    I_accum = Q_accum = 0;

    // 码相位控制
    CodeController(sync_flag, m_state, shift_counter);
  }
}