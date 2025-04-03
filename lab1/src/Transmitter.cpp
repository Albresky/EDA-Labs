/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved.
 *
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-04-03 12:30:22
 * @LastEditTime: 2025-04-03 14:28:16
 * @FilePath: /BUPT-EDA-Labs/lab1/src/Transmitter.cpp
 *
 * @Description: 扩频通信系统发送端模块实现
 */
#include "Transmitter.h"

// 构造函数，初始化发送端参数
Transmitter::Transmitter(ap_uint<5> initial_m_state)
    : m_state(initial_m_state), data_counter(0), current_data(0),
      current_code(0) {}

// 重置发送端状态，用于多次测试
void Transmitter::Reset(ap_uint<5> new_m_state) {
  m_state = new_m_state;
  data_counter = 0;
  current_data = 0;
  current_code = 0;
}

// 生成发送端 m 序列码片
ap_uint<1> Transmitter::GenerateMCode() {
  ap_uint<1> feedback = m_state[4] ^ m_state[2]; // 反馈多项式： x^5 + x^3 +1
  m_state = (m_state << 1) | feedback;
  return m_state[0]; // 输出最低位
}

// 量化浮点信号为 2 位采样值
sample_t Transmitter::QuantizeSample(float value) {
  if (value >= 1.5)
    return 0b01; // +1
  else if (value >= 0.5)
    return 0b01; // +1
  else if (value <= -1.5)
    return 0b10; // -2
  else if (value <= -0.5)
    return 0b11; // -1
  else
    return 0b00; // 0
}

// 生成调制后的 IF 信号（单个样本点）
sample_t Transmitter::GenerateSample(ap_uint<1> data_bit, int sample_idx) {
  // 每 1ms 更新数据位
  if (data_counter >= SAMPLE_RATE / 1000) {
    current_data = data_bit;
    data_counter = 0;
  }
  data_counter++;

  // 生成码片（每个码片 16 样点）
  int chip_idx = sample_idx % SAMPLES_PER_CHIP;
  if (chip_idx == 0) {
    current_code = GenerateMCode();
  }

  // 调制：D⊕M 后，输入极化函数
  ap_uint<1> xor_bit = current_data ^ current_code;
  float symbol = (xor_bit ? 1.0f : -1.0f);

  // 载波调制
  float phase = 2 * M_PI * CARRIER_FREQ * sample_idx / SAMPLE_RATE;
  float if_signal = symbol * cos(phase);

  // 量化: 加入噪声模拟实际 ADC
  if_signal += 0.1 * (rand() / (float)RAND_MAX - 0.5); // 5% 噪声
  return QuantizeSample(if_signal);
}

// 生成一组测试数据序列
std::vector<std::vector<ap_uint<1>>>
Transmitter::GenerateTestData(int num_test_cases) {
  std::vector<std::vector<ap_uint<1>>> all_test_data;

  for (int seed = 0; seed < num_test_cases; seed++) {
    srand(seed + 100);
    std::vector<ap_uint<1>> data_seq;

    // 为每个测试序列生成 10-20 位数据位
    int data_len = 10 + (seed % 11); // 10-20 位之间
    for (int i = 0; i < data_len; i++) {
      data_seq.push_back(rand() % 2);
    }
    all_test_data.push_back(data_seq);
  }

  return all_test_data;
}

// 生成多组不同的 m 码初始状态
std::vector<ap_uint<5>> Transmitter::GenerateMCodeStates(int num_test_cases) {
  std::vector<ap_uint<5>> states;
  ap_uint<5> base_state = 0b10101;

  // 对于每个测试用例，生成与基准状态相差 1 位的状态
  for (int i = 0; i < num_test_cases; i++) {
    if (i > 0) {
      // 循环右移 1 位
      ap_uint<1> last_bit = base_state[0];
      base_state = base_state >> 1;
      base_state[4] = last_bit;
    }
    states.push_back(base_state);
  }

  return states;
}