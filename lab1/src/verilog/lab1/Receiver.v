`timescale 1ns/1ps

module Receiver (
    input wire clk,
    input wire reset,
    input wire [4:0] rx_m_state,
    input wire [1:0] if_signal_in,
    input wire end_flag_in,
    output reg sync_flag_out
);
    // 参数定义
    parameter KP_GAIN = 32'h0028f5c3; // 0.01 in fixed point
    parameter CODE_LENGTH = 31;
    parameter SAMPLES_PER_CHIP = 16;
    parameter SAMPLES_PER_CODE = CODE_LENGTH * SAMPLES_PER_CHIP;
    parameter THRESHOLD = 32'h28000000; // 能量阈值(定点表示)
    
    // 内部信号
    reg [4:0] m_state;
    reg [31:0] phase_acc;
    reg signed [31:0] phi_est;
    reg signed [31:0] I_accum, Q_accum;
    reg signed [31:0] max_energy;
    reg sync_flag;
    
    // 计算所需信号
    wire m_code;
    wire signed [31:0] cos_wave, sin_wave;
    wire signed [31:0] I, Q;
    wire signed [31:0] phase_error;
    wire [15:0] sample_count;
    wire integral_done;
    
    // 实例化本地载波模块
    LocalCarrier local_carrier (
        .clk(clk),
        .reset(reset),
        .phi_est(phi_est),
        .phase_acc(phase_acc),
        .cos_out(cos_wave),
        .sin_out(sin_wave)
    );
    
    // M码生成模块
    wire [4:0] next_m_state;
    GenerateMCode mcode_gen (
        .clk(clk),
        .reset(reset),
        .init_state(m_state),
        .m_code(m_code),
        .state(next_m_state)
    );
    
    // 码相位控制器
    wire [4:0] adjusted_m_state;
    CodeController code_ctrl (
        .clk(clk),
        .reset(reset),
        .sync_flag(sync_flag),
        .m_state_in(next_m_state),
        .m_state_out(adjusted_m_state)
    );
    
    // 下变频模块
    wire signed [31:0] I_down, Q_down;
    DownConvert down_convert (
        .clk(clk),
        .reset(reset),
        .if_in(if_signal_in),
        .cos_phase(cos_wave),
        .sin_phase(sin_wave),
        .m_code(m_code),
        .I_out(I_down),
        .Q_out(Q_down)
    );
    
    // 积分器
    wire signed [31:0] I_sum, Q_sum;
    wire integral_complete;
    wire [15:0] sample_counter;
    Integrator integrator (
        .clk(clk),
        .reset(reset),
        .I_in(I_down),
        .Q_in(Q_down),
        .I_sum(I_sum),
        .Q_sum(Q_sum),
        .sample_count(sample_counter),
        .integral_done(integral_complete)
    );
    
    // 能量计算
    wire energy_sync_flag;
    wire signed [31:0] energy_max;
    EnergyCalc energy_calc (
        .clk(clk),
        .reset(reset),
        .I_sum(I_sum),
        .Q_sum(Q_sum),
        .sync_flag(energy_sync_flag),
        .max_energy(energy_max)
    );
    
    // 相位检测器
    wire signed [31:0] phi_error;
    PhaseDetector phase_detector (
        .I(I_sum),
        .Q(Q_sum),
        .phase_error(phi_error)
    );
    
    // 接收器状态更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            m_state <= rx_m_state;
            phase_acc <= 0;
            phi_est <= 0;
            sync_flag <= 0;
            sync_flag_out <= 0;
            max_energy <= 0;
        end else if (!end_flag_in) begin
            // 更新M码状态
            m_state <= adjusted_m_state;
            
            // 在积分完成后更新相关状态
            if (integral_complete) begin
                // 更新同步标志
                sync_flag <= energy_sync_flag;
                sync_flag_out <= energy_sync_flag;
                
                // 更新相位估计
                phi_est <= phi_est + ((phi_error * KP_GAIN) >>> 30);
                
                // 更新最大能量
                if (energy_max > max_energy) begin
                    max_energy <= energy_max;
                end
                
                // 如果同步成功，重置计数器
                if (energy_sync_flag) begin
                    phase_acc <= 0;
                end
            end else begin
                // 递增相位累加器
                phase_acc <= phase_acc + 1;
            end
        end
    end
endmodule
