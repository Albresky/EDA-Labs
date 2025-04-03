/*
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-04-01 19:45:26
 * @LastEditors: Albresky albre02@outlook.com
 * @LastEditTime: 2025-04-01 19:46:28
 * @FilePath: /BUPT-EDA-Labs/lab1/src/TopFunc.h
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置
 * 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
#include <ap_int.h>
#include <hls_math.h>
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

float PhaseDetector(float I, float Q);

ap_uint<1> GenerateMCode(ap_uint<5> &state);

void LocalCarrier(ap_uint<32> &phase_acc, float phi_est, float &cos_out,
                  float &sin_out);

void CodeController(bool sync_flag, ap_uint<5> &m_state);

void DownConvert(sample_t if_in, float cos_phase, float sin_phase,
                 ap_uint<1> m_code, float &I_out, float &Q_out);

void Integrator(float I_in, float Q_in, float &I_sum, float &Q_sum,
                ap_uint<16> &sample_count, bool &integral_done);

void EnergyCalc(float I_sum, float Q_sum, bool &sync_flag, float &max_energy);

void SpreadSpectrumSync(sample_t if_in, bool &sync_flag, ap_uint<1> &m_code_out,
                        ap_uint<5> &m_state, ap_uint<32> &phase_acc,
                        float *I_out = nullptr, float *Q_out = nullptr,
                        float *phi_est_out = nullptr);