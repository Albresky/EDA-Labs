`timescale 1ns/1ps

module PhaseDetector (
    input wire signed [31:0] I,  // I路积分值
    input wire signed [31:0] Q,  // Q路积分值
    output reg signed [31:0] phase_error  // 相位误差输出
);
    // 实现相位误差检测: phi_error = (I > 0) ? Q : -Q
    always @(*) begin
        if (I[31] == 0)  // I > 0
            phase_error = Q;
        else
            phase_error = -Q;
    end
endmodule
