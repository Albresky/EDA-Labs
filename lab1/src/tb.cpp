/*
 * Copyright (c) 2025 by Albresky, All Rights Reserved.
 *
 * @Author: Albresky albre02@outlook.com
 * @Date: 2025-03-18 19:14:30
 * @LastEditTime: 2025-04-03 14:27:08
 * @FilePath: /BUPT-EDA-Labs/lab1/src/tb.cpp
 *
 * @Description: 测试激励
 */
#include "TopFunc.h"
#include "Transmitter.h"
#include <algorithm>
#include <cmath>
#include <ctime>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>

using namespace std;

#define SIM_TIME_MS 1000                    // 每组测试的仿真时长(ms)
#define BIT_RATE 1000                       // 数据速率
#define SAMPLES_PER_MS (SAMPLE_RATE / 1000) // 每 ms 样点数
#define NUM_TEST_CASES 2                    // 测试的m码初始状态数量

/********************************** 运行单个测试用例
 * **********************************/
int RunTestCase(int test_case_idx, ap_uint<5> tx_m_state,
                vector<ap_uint<1>> &test_data, ofstream &summary_file) {
  // 初始化发送端
  Transmitter Transmitter(tx_m_state);

  hls::stream<sample_t> if_in_stream("if_in");
  hls::stream<bool> sync_flag_stream("sync_flag");
  hls::stream<ap_uint<1>> m_code_out_stream("m_code_out");
  hls::stream<ap_uint<5>> rx_m_state_stream("rx_m_state");
  hls::stream<ap_uint<32>> phase_acc_stream("phase_acc");
  hls::stream<DemodData> demod_stream("demod");
  hls::stream<float> phi_est_stream("phi_est");

  // 设置接收端初始状态，与发送端状态相差一位
  ap_uint<5> rx_m_state = tx_m_state;
  ap_uint<1> last_bit = rx_m_state[0];
  rx_m_state = rx_m_state >> 1;
  rx_m_state[4] = last_bit;

  ap_uint<32> phase_acc = 0;
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

  /*********************** 运行仿真 ***********************/
  bool sync_achieved = false;
  int sync_time = -1;
  float phase_est_value = 0.0;
  ap_uint<1> m_code_out = 0;
  bool sync_flag = false;
  DemodData demod_values;
  demod_values.I = 0.0;
  demod_values.Q = 0.0;

  rx_m_state_stream.write(rx_m_state);
  phase_acc_stream.write(phase_acc);
  for (int t = 0; t < SIM_TIME_MS * SAMPLES_PER_MS; t++) {
    // 选择当前数据位
    int data_idx = (t / SAMPLES_PER_MS) % DATA_LEN;
    ap_uint<1> data_bit = test_data[data_idx];

    // 使用发送端生成IF信号
    sample_t if_in_sample = Transmitter.GenerateSample(data_bit, t);

    if_in_stream.write(if_in_sample);

    // 接收端顶层函数
    SignalSync(if_in_stream, sync_flag_stream, m_code_out_stream,
               rx_m_state_stream, phase_acc_stream, demod_stream,
               phi_est_stream);

    if (!sync_flag_stream.empty()) {
      sync_flag = sync_flag_stream.read();
    }
    if (!m_code_out_stream.empty()) {
      m_code_out = m_code_out_stream.read();
    }
    if (!rx_m_state_stream.empty()) {
      rx_m_state = rx_m_state_stream.read();
    }
    if (!phase_acc_stream.empty()) {
      phase_acc = phase_acc_stream.read();
    }
    if (!demod_stream.empty()) {
      demod_values = demod_stream.read();
    }
    if (!phi_est_stream.empty()) {
      phase_est_value = phi_est_stream.read();
    }

    // 记录波形数据（每10个样点记录一次）
    if (t % 10 == 0) {
      logfile << t << ","                                 // 时间
              << if_in_sample.to_int() << ","             // 输入 IF 信号
              << sync_flag << ","                         // 同步标志
              << rx_m_state.to_uint() << ","              // 接收端 m 码状态
              << Transmitter.GetMState().to_uint() << "," // 发送端 m 码状态
              << phase_acc << ","                         // 相位累加器
              << m_code_out << ","                        // 输出 m 码
              << (int)Transmitter.GetCurrentCode() << "," // 发送端当前码片
              << demod_values.I << ","                    // I 路积分值
              << demod_values.Q << ","                    // Q 路积分值
              << phase_est_value                          // 相位估计值
              << endl;
    }

    // 检测同步
    if (sync_flag && !sync_achieved) {
      sync_achieved = true;
      sync_time = t;
      cout << "Test case " << test_case_idx << ": SYNC Achieved at " << t
           << " samples (" << t / (float)SAMPLES_PER_MS << " ms)" << endl;
    }

    if (sync_achieved && t > (sync_time + SAMPLES_PER_MS * 10)) {
      logfile << t << "," << if_in_sample.to_int() << "," << sync_flag << ","
              << rx_m_state.to_uint() << ","
              << Transmitter.GetMState().to_uint() << "," << phase_acc << ","
              << m_code_out << "," << (int)Transmitter.GetCurrentCode() << ","
              << demod_values.I << "," << demod_values.Q << ","
              << phase_est_value << endl;
      break;
    }

    // 最大同步时间上限
    if (t >= SIM_TIME_MS * SAMPLES_PER_MS - 1) {
      cout << "Test case " << test_case_idx
           << ": Failed to achieve sync within time limit!" << endl;
      break;
    }
  }

  // Clear all streams
  while (!if_in_stream.empty())
    if_in_stream.read();
  while (!sync_flag_stream.empty())
    sync_flag_stream.read();
  while (!m_code_out_stream.empty())
    m_code_out_stream.read();
  while (!rx_m_state_stream.empty())
    rx_m_state_stream.read();
  while (!phase_acc_stream.empty())
    phase_acc_stream.read();
  while (!demod_stream.empty())
    demod_stream.read();
  while (!phi_est_stream.empty())
    phi_est_stream.read();

  logfile.close();

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
  vector<vector<ap_uint<1>>> all_test_data =
      Transmitter::GenerateTestData(NUM_TEST_CASES);
  vector<ap_uint<5>> tx_m_states =
      Transmitter::GenerateMCodeStates(NUM_TEST_CASES);

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