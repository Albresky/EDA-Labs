`timescale 1ns/1ps

module DownConvert (
    input wire clk,
    input wire reset,
    input wire [1:0] if_in,         // 2位补码表示的IF信号
    input wire signed [31:0] cos_phase,  // 本地载波余弦
    input wire signed [31:0] sin_phase,  // 本地载波正弦
    input wire m_code,              // M码
    output reg signed [31:0] I_out, // I路输出
    output reg signed [31:0] Q_out  // Q路输出
);
    
    // 2位补码转浮点
    reg signed [31:0] if_float;
    
    always @(*) begin
        case (if_in)
            2'b11: if_float = -32'h40000000; // -1.0
            2'b10: if_float = -32'h20000000; // -0.5
            2'b00: if_float = 32'h20000000;  // 0.5
            default: if_float = 0;           // 01->0
        endcase
    end
    
    // 下变频乘法
    wire signed [31:0] m_code_factor;
    assign m_code_factor = m_code ? 32'h40000000 : -32'h40000000; // 1.0 or -1.0
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            I_out <= 0;
            Q_out <= 0;
        end else begin
            // 下变频与相关
            I_out <= (if_float * cos_phase * m_code_factor) >>> 30; // 右移调整定点数
            Q_out <= (if_float * sin_phase * m_code_factor) >>> 30;
        end
    end
endmodule
