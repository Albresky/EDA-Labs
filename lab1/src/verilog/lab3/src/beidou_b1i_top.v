`timescale 1ns / 1ps

module beidou_b1i_top (
    input wire clk,
    input wire rst_n,
    input wire ap_start,
    input wire signed [3:0] signal_buffer [0:16367],
    input wire [10:0] prn,
    output wire ap_done,
    output wire ap_idle,
    output wire ap_ready,
    output wire signal_detected,
    output wire [10:0] code_phase,
    output wire [7:0] doppler_bin,
    output wire [31:0] peak_metric,
    output wire [31:0] snr
);

    // FSM States
    localparam IDLE = 2'b00;
    localparam BUSY = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // Control signals
    reg acq_start;
    wire acq_ready;
    
    // Output registers
    reg signal_detected_reg;
    reg [10:0] code_phase_reg;
    reg [7:0] doppler_bin_reg;
    reg [31:0] peak_metric_reg;
    reg [31:0] snr_reg;
    
    // Instantiate acquisition core
    acquisition_core acq_core (
        .clk(clk),
        .rst_n(rst_n),
        .start(acq_start),
        .signal_buffer(signal_buffer),
        .prn(prn),
        .acq_ready(acq_ready),
        .signal_detected(signal_detected_reg),
        .code_phase(code_phase_reg),
        .doppler_bin(doppler_bin_reg),
        .peak_metric(peak_metric_reg),
        .snr(snr_reg)
    );
    
    // State machine control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = ap_start ? BUSY : IDLE;
            BUSY: next_state = acq_ready ? DONE : BUSY;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Control signal generation
    always @(*) begin
        acq_start = (state == IDLE && ap_start == 1'b1);
    end
    
    // AXI-lite control interface signals
    assign ap_idle = (state == IDLE);
    assign ap_done = (state == DONE);
    assign ap_ready = ap_done;
    
    // Output assignments
    assign signal_detected = signal_detected_reg;
    assign code_phase = code_phase_reg;
    assign doppler_bin = doppler_bin_reg;
    assign peak_metric = peak_metric_reg;
    assign snr = snr_reg;

endmodule
