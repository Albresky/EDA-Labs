/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved.
 *
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-03-18 19:14:30
 * @LastEditTime: 2025-04-04 16:07:16
 * @FilePath: /BUPT-EDA-Labs/lab1/src/tb.cpp
 *
 * @Description: 测试激励
 */
#include "TopFunc.h"

using namespace std;

// 生成32种不同的测试数据序列
vector<ap_uint<DATA_LEN>> GenerateTestData() {
  vector<ap_uint<DATA_LEN>> all_test_data;

  for (int seed = 0; seed < NUM_TEST_CASES; seed++) {
    srand(seed + 100);
    ap_uint<DATA_LEN> data_seq;

    for (int i = 0; i < DATA_LEN; i++) {
      data_seq[i] = rand() % 2;
    }
    all_test_data.push_back(data_seq);
  }

  return all_test_data;
}

// 生成32种不同的m码初始状态
vector<ap_uint<5>> GenerateMCodeStates() {
  vector<ap_uint<5>> states;

  ap_uint<5> base_state = 0b10101;

  // 对于每个测试用例，生成与基准状态相差1位的状态
  for (int i = 0; i < NUM_TEST_CASES; i++) {
    if (i > 0) {
      // 循环右移一位
      ap_uint<1> last_bit = base_state[0];
      base_state = base_state >> 1;
      base_state[4] = last_bit;
    }
    states.push_back(base_state);
  }

  return states;
}

// 运行单个测试用例
int RunTestCase(int test_case_idx, ap_uint<5> tx_m_state,
                ap_uint<DATA_LEN> &test_data) {
  /*********************** 运行仿真 ***********************/
  ap_uint<5> rx_m_state = tx_m_state;
  ap_uint<1> last_bit = rx_m_state[0];
  rx_m_state = rx_m_state >> 1;
  rx_m_state[4] = last_bit;

  ap_uint<1> sync_flag = false;

  TopFunc(test_data, tx_m_state, rx_m_state, sync_flag);

  if (sync_flag) {
    cout << "Sync achieved!" << endl;
  } else {
    cout << "Failed to achieve sync!" << endl;
  }

  return (int)sync_flag;
}

int main() {
  // 生成测试数据和 m 码初始状态
  vector<ap_uint<DATA_LEN>> all_test_data = GenerateTestData();
  vector<ap_uint<5>> tx_m_states = GenerateMCodeStates();

  int success_count = 0;

  // 运行所有测试用例
  for (int i = 0; i < NUM_TEST_CASES; i++) {
    int sync_time = RunTestCase(i, tx_m_states[i], all_test_data[i]);
    if (sync_time > 0) {
      success_count++;
    }

    srand(time(NULL) + i);
  }
}