`timescale 1ns/1ps

module Transmitter (
    input wire clk,
    input wire reset,
    input wire [4:0] tx_m_state,
    input wire [14:0] test_data,      // 测试数据序列
    input wire sync_flag_in,          // 从接收端来的同步标志
    output reg [1:0] if_signal_out,   // IF信号输出
    output reg end_flag_out           // 结束标志
);
    // 参数定义
    parameter CARRIER_FREQ = 124000;          // 载波频率
    parameter SAMPLE_RATE = 4 * CARRIER_FREQ; // 采样率
    parameter SAMPLES_PER_MS = SAMPLE_RATE / 1000;
    parameter SIM_TIME_MS = 1200;             // 最长仿真时间
    parameter DATA_LEN = 15;
    
    // 信号定义
    reg [4:0] m_state;
    reg [31:0] sample_counter;
    reg [31:0] max_samples;
    reg [3:0] data_index;
    reg current_data_bit;
    reg [9:0] data_counter;
    reg current_m_code;
    reg xor_bit;
    
    // 储存正弦波值
    reg signed [31:0] sin_table [0:15];
    
    initial begin
        sin_table[0] = 32'h40000000;  // 1.0
        sin_table[1] = 32'h3b20d79e;  // 0.866
        sin_table[2] = 32'h2d413ccc;  // 0.707
        sin_table[3] = 32'h187de2a7;  // 0.5
        sin_table[4] = 32'h00000000;  // 0.0
        sin_table[5] = 32'he782173b;  // -0.5
        sin_table[6] = 32'hd2bec333;  // -0.707
        sin_table[7] = 32'hc4df2862;  // -0.866
        sin_table[8] = 32'hc0000000;  // -1.0
        sin_table[9] = 32'hc4df2862;  // -0.866
        sin_table[10] = 32'hd2bec333; // -0.707
        sin_table[11] = 32'he782173b; // -0.5
        sin_table[12] = 32'h00000000; // 0.0
        sin_table[13] = 32'h187de2a7; // 0.5
        sin_table[14] = 32'h2d413ccc; // 0.707
        sin_table[15] = 32'h3b20d79e; // 0.866
    end
    
    // M码生成逻辑
    wire feedback;
    assign feedback = m_state[4] ^ m_state[2]; // x^5 + x^3 + 1
    
    // 生成IF信号
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            m_state <= tx_m_state;
            sample_counter <= 0;
            max_samples <= SAMPLES_PER_MS * SIM_TIME_MS;
            data_index <= 0;
            current_data_bit <= test_data[0];
            data_counter <= 0;
            current_m_code <= 0;
            xor_bit <= 0;
            if_signal_out <= 0;
            end_flag_out <= 0;
        end else begin
            // 检查是否接收到同步信号或达到最大仿真时间
            if (sync_flag_in || sample_counter >= max_samples) begin
                end_flag_out <= 1;
            end else begin
                // 每ms更新数据位
                if (data_counter >= SAMPLES_PER_MS) begin
                    data_counter <= 0;
                    data_index <= (data_index + 1) % DATA_LEN;
                    current_data_bit <= test_data[data_index];
                end else begin
                    data_counter <= data_counter + 1;
                end
                
                // 每16个样本更新M码
                if (sample_counter % 16 == 0) begin
                    // 生成M码
                    current_m_code <= m_state[0];
                    m_state <= {m_state[3:0], feedback};
                end
                
                // 调制: D⊕M
                xor_bit <= current_data_bit ^ current_m_code;
                
                // 载波调制
                if (xor_bit) begin
                    // 使用余弦波
                    if_signal_out <= (sin_table[sample_counter % 16][31]) ? 2'b11 : 2'b00; // 简化为正负
                end else begin
                    // 相反相位
                    if_signal_out <= (sin_table[sample_counter % 16][31]) ? 2'b00 : 2'b11;
                end
                
                sample_counter <= sample_counter + 1;
            end
        end
    end
endmodule
