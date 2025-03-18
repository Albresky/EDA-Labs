/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved. 
 * 
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-03-18 19:10:53
 * @LastEditTime: 2025-03-18 19:52:18
 * @FilePath: /BUPT-EDA-Labs/lab1/src/TopFunc.hpp
 * 
 * @Description: Top Function
 */
#include <ap_int.h>
#include <hls_math.h>

// 定义数据类型和常量
#define SAMPLE_RATE    496000   // 4倍载波频率
#define CODE_LENGTH    31       // m序列长度
#define THRESHOLD      500     // 同步阈值示例（需根据仿真调整）
typedef ap_int<2> sample_t;     // 2位补码输入

// 本地载波生成模块
void LocalCarrier(ap_uint<32> n, float phase, float &cos_out, float &sin_out) {
    #pragma HLS PIPELINE
    static float freq = 124000.0 * 2 * M_PI / SAMPLE_RATE;
    float angle = freq * n + phase;
    cos_out = hls::cosf(angle);
    sin_out = hls::sinf(angle);
}

// m序列生成器（31位Gold码示例）
ap_uint<1> GenerateMSequence(ap_uint<5> &state) {
    #pragma HLS PIPELINE
    ap_uint<1> new_bit = state[4] ^ state[1]; // LFSR反馈多项式
    state = (state << 1) | new_bit;
    return new_bit;
}

// 相关积分模块
void Correlator(
    sample_t if_in,
    float cos_phase,
    float sin_phase,
    ap_uint<1> m_code,
    float &I_acc,
    float &Q_acc,
    bool &sync_flag
) {
    #pragma HLS PIPELINE II=1
    #pragma HLS DATAFLOW

    // 下变频
    float if_float = if_in == 0b11 ? -1.0f : 1.0f; // 2位补码转换
    float I_mix = if_float * cos_phase;
    float Q_mix = if_float * sin_phase;

    // 码相关
    float code_factor = m_code ? 1.0f : -1.0f;
    float I_corr = I_mix * code_factor;
    float Q_corr = Q_mix * code_factor;

    // 积分器
    static float I_sum = 0, Q_sum = 0;
    static int count = 0;
    
    I_sum += I_corr;
    Q_sum += Q_corr;
    count++;

    // 1ms积分周期（496 samples）
    if (count == 496) {
        float S = I_sum*I_sum + Q_sum*Q_sum;
        sync_flag = (S > THRESHOLD);
        
        I_sum = Q_sum = 0;
        count = 0;
    }
}

// 顶层模块
void TopFunc(
    sample_t if_in,
    bool &sync_flag,
    ap_uint<5> &m_state,
    ap_uint<32> &sample_counter
) {
    #pragma HLS INTERFACE ap_ctrl_none port=return
    #pragma HLS PIPELINE II=1

    static float phase = 0;
    static bool searching = true;
    static int shift_count = 0;

    // 生成本地载波
    float cos_wave, sin_wave;
    LocalCarrier(sample_counter, phase, cos_wave, sin_wave);

    // 生成m序列
    ap_uint<1> m_code = GenerateMSequence(m_state);

    // 相关积分
    float I_acc, Q_acc;
    Correlator(if_in, cos_wave, sin_wave, m_code, I_acc, Q_acc, sync_flag);

    // 同步控制逻辑
    if (searching && !sync_flag) {
        shift_count++;
        if (shift_count >= CODE_LENGTH) {
            m_state = m_state >> 1; // 相位延迟
            shift_count = 0;
        }
    } else {
        searching = false;
    }

    sample_counter++;
}