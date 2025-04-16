`timescale 1ns / 1ps

module generate_carrier (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire signed [15:0] doppler_freq, // Signed fixed-point value for Doppler frequency
    output wire carrier_ready,
    output reg signed [31:0] carrier_real [0:16367], // B1I_SAMPLES_PER_CODE-1
    output reg signed [31:0] carrier_imag [0:16367]  // B1I_SAMPLES_PER_CODE-1
);

    // Parameters
    parameter B1I_SAMPLE_RATE = 16368000;  // 16.368 MHz

    // Use a LUT for sin/cos implementation
    // In a real design, would use CORDIC or ROM-based sin/cos lookup
    `include "sin_cos_lut.v"

    // State definitions
    localparam IDLE = 2'b00;
    localparam GENERATING = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [15:0] counter;
    reg [31:0] phase;  // Current phase value
    reg [31:0] phase_step; // Phase increment per sample
    
    // Calculation constants (scaled fixed-point for 2*PI)
    localparam TWO_PI = 32'h6487ED51; // 2π in Q7.25 format (2*3.14159... << 25)
    
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
            IDLE: next_state = start ? GENERATING : IDLE;
            GENERATING: next_state = (counter == 16'd16367) ? DONE : GENERATING;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Calculate phase step based on doppler frequency (2*π*doppler/sample_rate)
    function [31:0] calculate_phase_step;
        input signed [15:0] doppler;
        reg [47:0] temp;
        begin
            // Phase step = 2*PI*doppler/sample_rate
            // Use fixed-point arithmetic for precision
            // Multiply by 2*PI (Q7.25) then divide by sample rate
            temp = (doppler * TWO_PI) / B1I_SAMPLE_RATE;
            calculate_phase_step = temp[31:0];
        end
    endfunction
    
    // Carrier generation process
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            phase <= 32'd0;
            phase_step <= 32'd0;
        end else begin
            case (state)
                IDLE: begin
                    counter <= 16'd0;
                    phase <= 32'd0;
                    phase_step <= calculate_phase_step(doppler_freq);
                end
                
                GENERATING: begin
                    // Calculate sin/cos values using LUT
                    carrier_real[counter] <= cos_lut(phase);
                    carrier_imag[counter] <= sin_lut(phase);
                    
                    // Update phase for next sample
                    phase <= (phase + phase_step) % TWO_PI;
                    
                    // Increment counter
                    counter <= counter + 16'd1;
                end
                
                DONE: begin
                    // Hold state and results
                end
            endcase
        end
    end
    
    // Output ready signal
    assign carrier_ready = (state == DONE);

endmodule
