`timescale 1ns/1ps

module TopFunc (
    input wire clk,
    input wire reset,
    input wire [14:0] test_data,  // DATA_LEN = 15
    input wire [4:0] tx_m_state,
    input wire [4:0] rx_m_state,
    output reg sync_flag
);

    // 参数定义
    parameter CARRIER_FREQ = 124000;                      // 124kHz 载波
    parameter SAMPLE_RATE = 4 * CARRIER_FREQ;             // 496kHz 采样率
    parameter CODE_LENGTH = 31;                           // m 码长度
    parameter CHIP_RATE = 31000;                          // 31kHz 码片速率
    parameter SAMPLES_PER_CHIP = SAMPLE_RATE / CHIP_RATE; // 16 采样/码片
    parameter SAMPLES_PER_MS = SAMPLE_RATE / 1000;        // 每毫秒样本数
    
    // 信号声明
    wire [1:0] if_signal;
    wire end_flag;
    wire sync_flag_internal;
    
    // 实例化发送器和接收器
    Transmitter transmitter_inst (
        .clk(clk),
        .reset(reset),
        .tx_m_state(tx_m_state),
        .test_data(test_data),
        .sync_flag_in(sync_flag_internal),
        .if_signal_out(if_signal),
        .end_flag_out(end_flag)
    );
    
    Receiver receiver_inst (
        .clk(clk),
        .reset(reset),
        .rx_m_state(rx_m_state),
        .if_signal_in(if_signal),
        .end_flag_in(end_flag),
        .sync_flag_out(sync_flag_internal)
    );
    
    // 输出同步标志
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_flag <= 0;
        end else begin
            sync_flag <= sync_flag_internal;
        end
    end

endmodule
