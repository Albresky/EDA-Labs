`timescale 1ns/1ps

module Integrator (
    input wire clk,
    input wire reset,
    input wire signed [31:0] I_in,
    input wire signed [31:0] Q_in,
    output reg signed [31:0] I_sum,
    output reg signed [31:0] Q_sum,
    output reg [15:0] sample_count,
    output reg integral_done
);
    // 参数定义
    parameter CODE_LENGTH = 31;
    parameter SAMPLES_PER_CHIP = 16;
    parameter SAMPLES_PER_CODE = CODE_LENGTH * SAMPLES_PER_CHIP;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            I_sum <= 0;
            Q_sum <= 0;
            sample_count <= 0;
            integral_done <= 0;
        end else begin
            // 累加I和Q
            I_sum <= I_sum + I_in;
            Q_sum <= Q_sum + Q_in;
            
            // 检查是否完成一个积分周期
            if (sample_count + 1 >= SAMPLES_PER_CODE) begin
                sample_count <= 0;
                integral_done <= 1;
            end else begin
                sample_count <= sample_count + 1;
                integral_done <= 0;
            end
        end
    end
endmodule
