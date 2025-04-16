`timescale 1ns/1ps

module EnergyCalc (
    input wire clk,
    input wire reset,
    input wire signed [31:0] I_sum,
    input wire signed [31:0] Q_sum,
    output reg sync_flag,
    output reg signed [31:0] max_energy
);
    // 参数定义
    parameter THRESHOLD = 32'h28000000; // 能量阈值(定点表示)
    
    reg signed [63:0] energy;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_flag <= 0;
            max_energy <= 0;
            energy <= 0;
        end else begin
            // 计算能量 S = I_sum^2 + Q_sum^2
            energy <= ($signed(I_sum) * $signed(I_sum) + $signed(Q_sum) * $signed(Q_sum));
            
            // 检查是否超过阈值
            sync_flag <= (energy > THRESHOLD);
            
            // 更新最大能量
            if (energy > max_energy) begin
                max_energy <= energy[31:0]; // 取低32位作为输出
            end
        end
    end
endmodule
