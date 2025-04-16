/*
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-04-01 19:45:26
 * @LastEditors: Albresky albre02@outlook.com
 * @LastEditTime: 2025-04-08 19:22:47
 * @FilePath: /BUPT-EDA-Labs/lab1/src/TopFunc.h
 */
#ifndef TOP_FUNC_H
#define TOP_FUNC_H

#include <algorithm>
#include <ap_int.h>
#include <cmath>
#include <ctime>
#include <fstream>
#include <hls_math.h>
#include <hls_stream.h>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

#define CARRIER_FREQ 124000                               // 124kHz 载波
#define SAMPLE_RATE (4 * CARRIER_FREQ)                    // 496kHz 采样率
#define PHASE_INC (2 * M_PI * CARRIER_FREQ / SAMPLE_RATE) // 载波相位增量
#define CODE_LENGTH 31                                    // m 码长度
#define CHIP_RATE 31000                                   // 31kHz 码片速率
#define SAMPLES_PER_CHIP (SAMPLE_RATE / CHIP_RATE)        // 16 采样/码片
#define INTEGRAL_TIME 1                                   // 1ms 积分时间 Ts
#define THRESHOLD 40                                      // 能量阈值
#define KP_GAIN 0.01                                      // 环路增益

#define DATA_LEN 15

#define SIM_TIME_MS 1200                   // 每组测试的仿真时长(ms)
#define BIT_RATE 1000                       // 数据速率
#define SAMPLES_PER_MS (SAMPLE_RATE / 1000) // 每 ms 样点数
#define NUM_TEST_CASES 2                    // 测试的 m 码初始状态数量

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

float PhaseDetector(float I, float Q);

void CodeController(bool sync_flag, ap_uint<5> &m_state);

sample_t QuantizeSample(float value);

ap_uint<1> GenerateMCode(ap_uint<5> &state);

ap_uint<1> GenerateTxMCode(ap_uint<5> &state);

void LocalCarrier(ap_uint<32> &phase_acc, float phi_est, float &cos_out,
                  float &sin_out);

void DownConvert(sample_t if_in, float cos_phase, float sin_phase,
                 ap_uint<1> m_code, float &I_out, float &Q_out);

void Integrator(float &I_in, float &Q_in, float &I_sum, float &Q_sum,
                ap_uint<16> &sample_count, ap_uint<1> &integral_done);

void EnergyCalc(float I_sum, float Q_sum, ap_uint<1> &sync_flag,
                float &max_energy);

void transmitter_wrapper(ap_uint<5> tx_m_state, ap_uint<5> rx_m_state,
                         ap_uint<DATA_LEN> &test_data,
                         ap_uint<1> &sync_flag_out,
                         hls::stream<ap_uint<1>> &sync_flag_in_strm,
                         hls::stream<ap_uint<1>> &end_flag_out_strm,
                         hls::stream<sample_t> &if_signal_out_strm);

void receiver_wrapper(ap_uint<5> rx_m_state,
                      hls::stream<sample_t> &if_signal_in_strm,
                      hls::stream<ap_uint<1>> &end_flag_in_strm,
                      hls::stream<ap_uint<1>> &sync_flag_out_strm);

void TopFunc(ap_uint<DATA_LEN> test_data, ap_uint<5> tx_m_state,
             ap_uint<5> rx_m_state, ap_uint<1> &sync_flag);

#endif // TOP_FUNC_H