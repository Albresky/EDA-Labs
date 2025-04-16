`timescale 1ns/1ps

module LocalCarrier (
    input wire clk,
    input wire reset,
    input wire signed [31:0] phi_est,  // 相位估计
    output reg [31:0] phase_acc,       // 相位累加器
    output reg signed [31:0] cos_out,  // 余弦输出
    output reg signed [31:0] sin_out   // 正弦输出
);
    // 参数定义
    parameter CARRIER_FREQ = 124000;
    parameter SAMPLE_RATE = 496000;
    parameter PHASE_INC = 32'h0477D1A; // 固定点表示的2*PI*CARRIER_FREQ/SAMPLE_RATE
    
    // 相位计算
    reg signed [31:0] phase;
    
    // 使用查找表实现三角函数
    reg [7:0] lut_index;
    reg signed [31:0] cos_lut [0:255];
    reg signed [31:0] sin_lut [0:255];
    
    integer i;
    initial begin
        // 初始化查找表
        for (i = 0; i < 256; i = i + 1) begin
            cos_lut[i] = $rtoi($cos(2.0 * 3.14159 * i / 256.0) * (2.0 ** 30));
            sin_lut[i] = $rtoi($sin(2.0 * 3.14159 * i / 256.0) * (2.0 ** 30));
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            phase_acc <= 0;
            phase <= 0;
            cos_out <= 0;
            sin_out <= 0;
        end else begin
            // 计算相位
            phase <= (phase_acc * PHASE_INC) + phi_est;
            
            // 计算查找表索引
            lut_index <= (phase >> 24) & 8'hFF;
            
            // 输出三角函数值
            cos_out <= cos_lut[lut_index];
            sin_out <= sin_lut[lut_index];
            
            // 更新相位累加器
            phase_acc <= phase_acc + 1;
        end
    end
endmodule
