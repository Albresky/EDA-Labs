/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved.
 *
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-03-18 19:14:30
 * @LastEditTime: 2025-03-30 16:41:56
 * @FilePath: /BUPT-EDA-Labs/lab1/src/tb.cpp
 *
 * @Description: Testbench for Top Function
 */
#include "TopFunc.hpp"
#include <algorithm>
#include <cmath>
#include <ctime>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

using namespace std;

#define SIM_TIME_MS 10000                   // 每组测试的仿真时长(ms)
#define BIT_RATE 1000                       // 数据速率
#define SAMPLES_PER_MS (SAMPLE_RATE / 1000) // 每 ms 样点数
#define NUM_TEST_CASES 32                   // 测试的m码初始状态数量

// 2 位补码转换
sample_t QuantizeSample(float value) {
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

// 发送端 m 序列生成器（与接收端一致）
ap_uint<1> GenerateTxMCode(ap_uint<5> &state) {
  ap_uint<1> feedback = state[4] ^ state[2];
  state = (state << 1) | feedback;
  return state[0];
}

// IFin 信号生成器
sample_t GenerateIFSignal(ap_uint<1> data_bit, ap_uint<5> &tx_m_state,
                          int sample_idx) {
  // 数据位持续时间（1ms=496样点）
  static int data_counter = 0;
  static ap_uint<1> current_data = 0;
  static ap_uint<1> current_code = 0;

  // 每 1ms 更新数据位
  if (data_counter >= SAMPLES_PER_MS) {
    current_data = data_bit;
    data_counter = 0;
  }
  data_counter++;

  // 生成码片（31 码片/ms，每个码片 16 样点）
  int chip_idx = sample_idx % 16;
  if (chip_idx == 0) {
    ap_uint<1> m_code = GenerateTxMCode(tx_m_state);
    current_code = m_code;
  }

  // 调制：D⊕M 后，输入极化函数
  ap_uint<1> xor_bit = current_data ^ current_code;
  float symbol = (xor_bit ? 1.0f : -1.0f);

  // 载波调制
  float phase = 2 * M_PI * CARRIER_FREQ * sample_idx / SAMPLE_RATE;
  float if_signal = symbol * cos(phase);

  // 量化（加入噪声模拟实际 ADC）
  if_signal += 0.1 * (rand() / (float)RAND_MAX - 0.5); // 添加 5% 噪声
  return QuantizeSample(if_signal);
}

// 生成32种不同的测试数据序列
vector<vector<ap_uint<1>>> GenerateTestData() {
  vector<vector<ap_uint<1>>> all_test_data;

  // 基于不同种子生成32种测试数据序列
  for (int seed = 0; seed < NUM_TEST_CASES; seed++) {
    srand(seed + 100); // 不同的随机种子
    vector<ap_uint<1>> data_seq;

    // 为每个测试序列生成10-20位数据位
    int data_len = 10 + (seed % 11); // 10到20位之间
    for (int i = 0; i < data_len; i++) {
      data_seq.push_back(rand() % 2);
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
    // 每次循环将基准状态右移一位（模拟码相位差）
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

/********************************** 运行单个测试用例 **********************************/
int RunTestCase(int test_case_idx, ap_uint<5> tx_m_state,
                vector<ap_uint<1>> &test_data, ofstream &summary_file) {
  sample_t if_in;
  bool sync_flag = false;

  // 设置接收端初始状态，与发送端状态相差一位
  ap_uint<5> rx_m_state = tx_m_state;
  ap_uint<1> last_bit = rx_m_state[0];
  rx_m_state = rx_m_state >> 1;
  rx_m_state[4] = last_bit;

  ap_uint<32> phase_acc = 0;
  ap_uint<1> m_code_out;
  const int DATA_LEN = test_data.size();

  // 创建CSV文件存储此测试用例的波形数据
  string filename = "waveform_case_" + to_string(test_case_idx) + ".csv";
  ofstream logfile(filename);
  logfile << "Time(n),IF_in,Sync_Flag,Rx_State,Tx_State,Phase_Acc,M_Code_Out,"
             "Tx_Code,I_Value,Q_Value,Phase_Est"
          << endl;

  cout << "Running test case " << test_case_idx << " with TX state: 0b"
       << setw(5) << setfill('0') << hex << tx_m_state.to_uint()
       << ", RX state: 0b" << setw(5) << setfill('0') << hex
       << rx_m_state.to_uint() << ", data length: " << dec << DATA_LEN << endl;

  // 运行仿真
  bool sync_achieved = false;
  int sync_time = -1;
  float phase_est_value = 0.0; // 记录相位估计值
  ap_uint<1> tx_code;          // 发送端码值

  for (int t = 0; t < SIM_TIME_MS * SAMPLES_PER_MS; t++) {
    // 生成当前数据位索引
    int data_idx = (t / SAMPLES_PER_MS) % DATA_LEN;
    ap_uint<1> data_bit = test_data[data_idx];

    // 计算当前发送端码值（每16个样点更新一次）
    if (t % SAMPLES_PER_CHIP == 0) {
      ap_uint<5> temp_state = tx_m_state; // 创建临时副本避免修改发送端状态
      tx_code = GenerateTxMCode(temp_state);
    }

    // 生成IF信号（发送端）
    if_in = GenerateIFSignal(data_bit, tx_m_state, t);

    // 调用被测模块（接收端）并获取相位估计值
    static float I_value = 0.0, Q_value = 0.0;
    SpreadSpectrumSync(if_in, sync_flag, m_code_out, rx_m_state, phase_acc,
                       &I_value, &Q_value, &phase_est_value);

    // 记录波形数据
    // 每10个样点记录数据
    if (t % 10 == 0) {
      logfile << t << ","                    // 时间
              << if_in.to_int() << ","       // 输入IF信号
              << sync_flag << ","            // 同步标志
              << rx_m_state.to_uint() << "," // 接收端m码状态
              << tx_m_state.to_uint() << "," // 发送端m码状态
              << phase_acc << ","            // 相位累加器
              << m_code_out << ","           // 输出m码
              << (int)tx_code << ","         // 发送端m码
              << I_value << ","              // I路积分值
              << Q_value << ","              // Q路积分值
              << phase_est_value             // 相位估计值
              << endl;
    }

    // 检测同步
    if (sync_flag && !sync_achieved) {
      sync_achieved = true;
      sync_time = t;
      cout << "Test case " << test_case_idx << ": SYNC Achieved at " << t
           << " samples (" << t / (float)SAMPLES_PER_MS << " ms)" << endl;
    }

    // 同步后继续运行一段时间，观察稳定性
    if (sync_achieved && t > (sync_time + SAMPLES_PER_MS * 10))
      break;

    // 如果超过最大时间还没同步，则终止此测试用例
    if (t >= SIM_TIME_MS * SAMPLES_PER_MS - 1) {
      cout << "Test case " << test_case_idx
           << ": Failed to achieve sync within time limit!" << endl;
      break;
    }
  }

  logfile.close();

  // 记录测试结果摘要
  summary_file << test_case_idx << ","
               << "0b" << setw(5) << setfill('0') << hex << tx_m_state.to_uint()
               << "," << dec << (sync_achieved ? "Success" : "Failure") << ","
               << (sync_achieved ? to_string(sync_time) : "N/A") << ","
               << (sync_achieved ? to_string(sync_time / (float)SAMPLES_PER_MS)
                                 : "N/A")
               << endl;

  return sync_achieved ? sync_time : -1;
}
/*----------------------------------------------------------------------------------*/


int main() {
  // 生成测试数据和 m 码初始状态
  vector<vector<ap_uint<1>>> all_test_data = GenerateTestData();
  vector<ap_uint<5>> tx_m_states = GenerateMCodeStates();

  // 创建测试结果摘要文件
  ofstream summary_file("test_summary.csv");
  summary_file << "Test Case,TX M-Code State,Sync Result,Sync Time "
                  "(samples),Sync Time (ms)"
               << endl;

  int success_count = 0;
  float avg_sync_time = 0;
  vector<int> sync_times;

  // 运行所有测试用例
  for (int i = 0; i < NUM_TEST_CASES; i++) {
    int sync_time =
        RunTestCase(i, tx_m_states[i], all_test_data[i], summary_file);
    if (sync_time >= 0) {
      success_count++;
      sync_times.push_back(sync_time);
      avg_sync_time += sync_time;
    }

    srand(time(NULL) + i);

    cout << "--------------------------------" << endl;
  }

  // 计算统计信息
  if (success_count > 0) {
    avg_sync_time /= success_count;

    int min_sync = *min_element(sync_times.begin(), sync_times.end());
    int max_sync = *max_element(sync_times.begin(), sync_times.end());

    summary_file << "\nSummary Statistics" << endl;
    summary_file << "Total Test Cases," << NUM_TEST_CASES << endl;
    summary_file << "Success Rate," << success_count << "/" << NUM_TEST_CASES
                 << " (" << (100.0 * success_count / NUM_TEST_CASES) << "%)"
                 << endl;
    summary_file << "Average Sync Time," << avg_sync_time << " samples ("
                 << avg_sync_time / SAMPLES_PER_MS << " ms)" << endl;
    summary_file << "Fastest Sync," << min_sync << " samples ("
                 << min_sync / SAMPLES_PER_MS << " ms)" << endl;
    summary_file << "Slowest Sync," << max_sync << " samples ("
                 << max_sync / SAMPLES_PER_MS << " ms)" << endl;

    cout << "\n============= TEST SUMMARY =============" << endl;
    cout << "Success Rate: " << success_count << "/" << NUM_TEST_CASES << " ("
         << (100.0 * success_count / NUM_TEST_CASES) << "%)" << endl;
    cout << "Average Sync Time: " << avg_sync_time / SAMPLES_PER_MS << " ms"
         << endl;
    cout << "Fastest Sync: " << min_sync / SAMPLES_PER_MS << " ms" << endl;
    cout << "Slowest Sync: " << max_sync / SAMPLES_PER_MS << " ms" << endl;
    cout << "=======================================" << endl;
  }

  summary_file.close();
  return 0;
}