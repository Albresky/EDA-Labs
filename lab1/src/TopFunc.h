/*
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-04-01 19:45:26
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-03 14:23:46
 * @FilePath: /BUPT-EDA-Labs/lab1/src/TopFunc.h
 */
#ifndef TOP_FUNC_H
#define TOP_FUNC_H

#include <ap_int.h>
#include <hls_math.h>
#include <hls_stream.h>
#include <iostream>

#define CARRIER_FREQ 124000                               // 124kHz 载波
#define SAMPLE_RATE (4 * CARRIER_FREQ)                    // 496kHz 采样率
#define PHASE_INC (2 * M_PI * CARRIER_FREQ / SAMPLE_RATE) // 载波相位增量
#define CODE_LENGTH 31                                    // m 码长度
#define CHIP_RATE 31000                                   // 31kHz 码片速率
#define SAMPLES_PER_CHIP (SAMPLE_RATE / CHIP_RATE)        // 16 采样/码片
#define INTEGRAL_TIME 1                                   // 1ms 积分时间 Ts
#define THRESHOLD 25                                      // 能量阈值
#define KP_GAIN 0.01                                      // 环路增益

typedef ap_int<2> sample_t; // 2位补码输入

#define STREAM_DEPTH 4096

struct PhaseData {
  float cos_wave;
  float sin_wave;
};

struct DemodData {
  float I;
  float Q;
};

struct IntegralData {
  float I_sum;
  float Q_sum;
  bool integral_done;
};

struct SyncData {
  bool sync_flag;
  float phase_error;
};

void PhaseDetector(hls::stream<DemodData> &input_stream,
                   hls::stream<float> &phase_error_stream);

void GenerateMCode(hls::stream<ap_uint<5>> &state_in,
                   hls::stream<ap_uint<5>> &state_out,
                   hls::stream<ap_uint<1>> &code_out);

void LocalCarrier(hls::stream<ap_uint<32>> &phase_acc_in,
                  hls::stream<ap_uint<32>> &phase_acc_out,
                  hls::stream<float> &phi_est,
                  hls::stream<PhaseData> &out_stream);

void CodeController(hls::stream<SyncData> &sync_stream,
                    hls::stream<ap_uint<5>> &m_state_in,
                    hls::stream<ap_uint<5>> &m_state_out);

void DownConvert(hls::stream<sample_t> &if_in,
                 hls::stream<PhaseData> &carrier_stream,
                 hls::stream<ap_uint<1>> &m_code,
                 hls::stream<DemodData> &out_stream);

void Integrator(hls::stream<DemodData> &in_stream,
                hls::stream<IntegralData> &out_stream,
                hls::stream<ap_uint<16>> &sample_count_in,
                hls::stream<ap_uint<16>> &sample_count_out);

void EnergyCalc(hls::stream<IntegralData> &in_stream,
                hls::stream<SyncData> &out_stream,
                hls::stream<float> &max_energy_in,
                hls::stream<float> &max_energy_out);

void SignalSync(hls::stream<sample_t> &if_in, hls::stream<bool> &sync_flag_out,
                hls::stream<ap_uint<1>> &m_code_out,
                hls::stream<ap_uint<5>> &m_state_out,
                hls::stream<ap_uint<32>> &phase_acc_out,
                hls::stream<DemodData> &demod_out,
                hls::stream<float> &phi_est_out);

#endif // TOP_FUNC_H