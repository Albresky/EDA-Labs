/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved.
 *
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-04-03 12:30:15
 * @LastEditTime: 2025-04-03 14:02:41
 * @FilePath: /BUPT-EDA-Labs/lab1/src/Transmitter.h
 *
 * @Description: 扩频通信系统发送端模块
 */
#ifndef Transmitter_H
#define Transmitter_H

#include "TopFunc.h"
#include <cmath>
#include <cstdlib>
#include <vector>

class Transmitter {
public:
  Transmitter(ap_uint<5> initial_m_state);

  void Reset(ap_uint<5> new_m_state);

  ap_uint<1> GenerateMCode();

  sample_t GenerateSample(ap_uint<1> data_bit, int sample_idx);

  static std::vector<std::vector<ap_uint<1>>>
  GenerateTestData(int num_test_cases);

  static std::vector<ap_uint<5>> GenerateMCodeStates(int num_test_cases);

  ap_uint<5> GetMState() const { return m_state; }

  ap_uint<1> GetCurrentCode() const { return current_code; }

private:
  ap_uint<5> m_state;      // m码状态寄存器
  int data_counter;        // 数据位计数器
  ap_uint<1> current_data; // 当前数据位
  ap_uint<1> current_code; // 当前码片

  sample_t QuantizeSample(float value);
};

#endif // Transmitter_H