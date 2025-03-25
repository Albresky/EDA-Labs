/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved. 
 * 
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-03-18 19:14:30
 * @LastEditTime: 2025-03-25 19:34:50
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
#define SIM_TIME_MS     1000       // 仿真时长(ms)
#define CARRIER_FREQ    124000   // 载波频率
#define BIT_RATE        1000     // 数据速率
#define CODE_RATE       31000    // 码片速率
#define SAMPLES_PER_MS  (SAMPLE_RATE/1000)  // 每ms样点数

// 2位补码转换（精确量化）
sample_t QuantizeSample(float value) {
    if(value >= 1.5) return 0b01;   // +1
    else if(value >= 0.5) return 0b01;
    else if(value <= -1.5) return 0b10; // -2
    else if(value <= -0.5) return 0b11; // -1
    else return 0b00;  // 0
}

// 发送端m序列生成器（与接收端一致）
ap_uint<1> GenerateTxMCode(ap_uint<5> &state) {
    ap_uint<1> feedback = state[4] ^ state[2]; // x^5 + x^3 +1
    state = (state << 1) | feedback;
    return state[0];
}

// IFin信号生成器（精确模型）
sample_t GenerateIFSignal(
    ap_uint<1> data_bit,
    ap_uint<5> &tx_m_state,
    int sample_idx
) {
    // 数据位持续时间（1ms=496样点）
    static int data_counter = 0;
    static ap_uint<1> current_data = 0;
    static ap_uint<1> current_code = 0;
    
    // 每1ms更新数据位
    if(data_counter >= SAMPLES_PER_MS) {
        current_data = data_bit;
        data_counter = 0;
    }
    data_counter++;

    // 生成码片（31码片/ms，每个码片16样点）
    int chip_idx = sample_idx % 16;
    if(chip_idx == 0) {
        ap_uint<1> m_code = GenerateTxMCode(tx_m_state);
        current_code = m_code;
    }

    // 调制：D⊕M 通过极化函数
    ap_uint<1> xor_bit = current_data ^ current_code;
    float symbol = (xor_bit ? 1.0f : -1.0f);

    // 载波调制
    float phase = 2 * M_PI * CARRIER_FREQ * sample_idx / SAMPLE_RATE;
    float if_signal = symbol * cos(phase);

    // 量化（加入噪声模拟实际ADC）
    if_signal += 0.1*(rand()/(float)RAND_MAX - 0.5); // 添加5%噪声
    return QuantizeSample(if_signal);
}

int main() {
    // 初始化
    sample_t if_in;
    bool sync_flag = false;
    ap_uint<5> rx_m_state = 0b11111;  // 接收端初始状态
    ap_uint<32> phase_acc = 0;
    ap_uint<1> m_code_out;

    // 发送端初始状态（必须与接收端不同以测试同步）
    ap_uint<5> tx_m_state = 0b11110;  // 初始相位差

    // 测试数据（重复序列）
    ap_uint<1> test_data[] = {0,1,0,1,1,0,0,1,0,1};
    const int DATA_LEN = sizeof(test_data)/sizeof(ap_uint<1>);

    // 打开波形记录文件
    ofstream logfile("waveform.csv");
    logfile << "Time(n),IF_in,Sync_Flag,Rx_State,Phase_Acc,M_Code_Out" << endl;

    // 运行仿真
    bool sync_achieved = false;
    for(int t=0; t<SIM_TIME_MS*SAMPLES_PER_MS; t++) {
        // 生成当前数据位索引
        int data_idx = (t / SAMPLES_PER_MS) % DATA_LEN;
        ap_uint<1> data_bit = test_data[data_idx];

        // 生成IF信号（发送端）
        if_in = GenerateIFSignal(data_bit, tx_m_state, t);

        // 调用被测模块（接收端）
        SpreadSpectrumSync(if_in, sync_flag, m_code_out, rx_m_state, phase_acc);

        // 记录波形
        logfile << t << ","
               << if_in.to_int() << ","
               << sync_flag << ","
               << rx_m_state.to_uint() << ","
               << phase_acc << ","
               << m_code_out << endl;

        // 同步成功后继续运行100样点
        if(sync_flag && !sync_achieved) {
            cout << "SYNC Achieved at " << t << " samples ("
                 << t/(float)SAMPLES_PER_MS << " ms)" << endl;
            sync_achieved = true;
        }
        if(sync_achieved && t > sync_achieved*1.2) break;
    }

    logfile.close();
    return 0;
}