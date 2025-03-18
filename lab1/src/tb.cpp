/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved. 
 * 
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-03-18 19:14:30
 * @LastEditTime: 2025-03-18 19:21:46
 * @FilePath: /BUPT-EDA-Labs/lab1/src/tb.cpp
 * 
 * @Description: Testbench source code
 */
#include <iostream>
#include <fstream>
#include <cmath>
#include "TopFunc.hpp"

using namespace std;

// 参数定义
#define SIM_TIME_MS 10      // 仿真时长(ms)
#define SAMPLE_RATE 496000  // 采样率
#define BIT_RATE     1000   // 数据速率
#define CODE_RATE    31000  // 码片速率

// 2位补码转换宏
#define TO_SAMPLE_T(x) ((x) > 0 ? 0b01 : 0b11)

// 全局信号记录
ofstream logfile("waveform.csv");

// 生成测试m序列（与设计一致）
ap_uint<1> GenerateTestMSeq(ap_uint<5> &state) {
    ap_uint<1> new_bit = state[4] ^ state[1];
    state = (state << 1) | new_bit;
    return new_bit;
}

// IFin信号生成器
sample_t GenerateIFSignal(ap_uint<1> data_bit, ap_uint<5> &m_state, int n) {
    static ap_uint<1> data_reg = 0;
    static int bit_counter = 0;
    
    // 每1ms更新数据位
    if (n % (SAMPLE_RATE/BIT_RATE) == 0) {
        data_reg = data_bit;  // 测试数据可在此修改
        bit_counter = 0;
    }
    
    // 生成当前码片
    if (bit_counter % (CODE_RATE/BIT_RATE) == 0) {
        m_state = 0b11111; // 发送端初始状态
    }
    ap_uint<1> m_code = GenerateTestMSeq(m_state);
    bit_counter++;

    // 信号生成
    ap_uint<1> xor_result = data_reg ^ m_code;
    float phase = 2 * M_PI * 124000 * n / float(SAMPLE_RATE);
    float value = (xor_result ? 1.0f : -1.0f) * cos(phase);
    
    return TO_SAMPLE_T(value);
}

// 主测试程序
int main() {
    // 初始化
    sample_t if_in;
    bool sync_flag;
    ap_uint<5> m_state = 0b11111; // 本地初始状态
    ap_uint<32> counter = 0;
    
    // 测试数据定义（可修改）
    ap_uint<1> test_data[] = {0,1,0,1,1,0,0,1,0,1,1,1,1,1,0}; // 10位测试数据
    
    logfile << "Time(n),IF_in,Sync_Flag" << endl;

    std::cout << "Dumping log into file: " << "waveform.csv" << std::endl;

    // 运行仿真
    for (int t=0; t<SIM_TIME_MS*(SAMPLE_RATE/1000); t++) {
        // 生成当前数据位（周期1ms）
        int data_idx = t / (SAMPLE_RATE/BIT_RATE);
        ap_uint<1> data_bit = test_data[data_idx % 10];
        
        // 生成IFin信号
        ap_uint<5> tx_m_state;
        if_in = GenerateIFSignal(data_bit, tx_m_state, t);
        
        // 调用被测模块
        TopFunc(if_in, sync_flag, m_state, counter);
        
        // 记录波形
        logfile << t << "," << if_in.to_int() << "," << sync_flag << endl;
        
        // 终止判断
        if (sync_flag) {
            cout << "SYNC ACHIEVED at " << t << " samples (" 
                 << t/(SAMPLE_RATE/1000.0) << " ms)" << endl;
            break;
        }
    }
    
    logfile.close();
    return 0;
}