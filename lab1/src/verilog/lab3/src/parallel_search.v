`timescale 1ns / 1ps

module parallel_search (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire signed [3:0] signal_samples [0:16367],  // Input signal samples
    input wire [2045:0] code_samples,                  // PRN code chips
    input wire signed [31:0] carrier_real [0:16367],   // Local carrier real part
    input wire signed [31:0] carrier_imag [0:16367],   // Local carrier imaginary part
    input wire [7:0] doppler_bin,                      // Current Doppler bin
    output wire search_ready,
    output reg [31:0] correlation_results [0:2045]     // Correlation result for each code phase
);

    // Parameters
    parameter B1I_CODE_LENGTH = 2046;
    parameter B1I_SAMPLES_PER_CODE = 16368;
    parameter B1I_SAMPLES_PER_CHIP = 8;
    
    // State definitions
    localparam IDLE = 3'b000;
    localparam UPSAMPLE_CODE = 3'b001;
    localparam MIX_SIGNALS = 3'b010;
    localparam CORRELATE = 3'b011;
    localparam DONE = 3'b100;
    
    reg [2:0] state, next_state;
    
    // Counters for different processing stages
    reg [15:0] upsample_counter;
    reg [15:0] mix_counter;
    reg [15:0] corr_phase_counter;
    reg [15:0] corr_sample_counter;
    
    // Intermediate data storage
    reg signed [31:0] upsampled_code_real [0:16367];
    reg signed [31:0] mixed_signal_real [0:16367];
    reg signed [31:0] mixed_signal_imag [0:16367];
    
    // Correlation accumulation registers
    reg signed [31:0] corr_real;
    reg signed [31:0] corr_imag;
    
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
            IDLE: next_state = start ? UPSAMPLE_CODE : IDLE;
            UPSAMPLE_CODE: next_state = (upsample_counter >= B1I_SAMPLES_PER_CODE-1) ? MIX_SIGNALS : UPSAMPLE_CODE;
            MIX_SIGNALS: next_state = (mix_counter >= B1I_SAMPLES_PER_CODE-1) ? CORRELATE : MIX_SIGNALS;
            CORRELATE: next_state = (corr_phase_counter >= B1I_CODE_LENGTH-1) ? DONE : CORRELATE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Main processing blocks
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            upsample_counter <= 16'd0;
            mix_counter <= 16'd0;
            corr_phase_counter <= 16'd0;
            corr_sample_counter <= 16'd0;
            corr_real <= 32'd0;
            corr_imag <= 32'd0;
        end else begin
            case (state)
                IDLE: begin
                    upsample_counter <= 16'd0;
                    mix_counter <= 16'd0;
                    corr_phase_counter <= 16'd0;
                    corr_sample_counter <= 16'd0;
                end
                
                UPSAMPLE_CODE: begin
                    // Create upsampled code
                    // i = upsample_counter / SAMPLES_PER_CHIP
                    // j = upsample_counter % SAMPLES_PER_CHIP
                    if (upsample_counter < B1I_SAMPLES_PER_CODE) begin
                        if (code_samples[upsample_counter/B1I_SAMPLES_PER_CHIP])
                            upsampled_code_real[upsample_counter] <= 32'h00100000; // 1.0 in fixed-point
                        else
                            upsampled_code_real[upsample_counter] <= 32'hFFF00000; // -1.0 in fixed-point
                        
                        upsample_counter <= upsample_counter + 16'd1;
                    end
                end
                
                MIX_SIGNALS: begin
                    if (mix_counter < B1I_SAMPLES_PER_CODE) begin
                        // Convert signal sample to fixed point and normalize
                        // signal_float = signal_samples[mix_counter] / 8.0
                        // Assuming 4-bit samples scaled to full range (-8 to +7)
                        
                        // Mix with carrier
                        // mixed_real = signal_float * carrier_real
                        // mixed_imag = signal_float * carrier_imag
                        
                        // Apply code to mixed signal
                        // mixed_signal_real = mixed_real * upsampled_code_real
                        // mixed_signal_imag = mixed_imag * upsampled_code_real
                        
                        // Implementation with fixed-point math (simplified)
                        mixed_signal_real[mix_counter] <= (signal_samples[mix_counter] * carrier_real[mix_counter] * upsampled_code_real[mix_counter]) >>> 3;
                        mixed_signal_imag[mix_counter] <= (signal_samples[mix_counter] * carrier_imag[mix_counter] * upsampled_code_real[mix_counter]) >>> 3;
                        
                        mix_counter <= mix_counter + 16'd1;
                    end
                end
                
                CORRELATE: begin
                    // Reset correlation accumulators for a new phase
                    if (corr_sample_counter == 0) begin
                        corr_real <= 32'd0;
                        corr_imag <= 32'd0;
                    end
                    
                    // Accumulate correlation for current phase
                    if (corr_sample_counter < B1I_SAMPLES_PER_CODE) begin
                        // Calculate index with circular buffer logic
                        // idx = (corr_sample_counter + corr_phase_counter * B1I_SAMPLES_PER_CHIP) % B1I_SAMPLES_PER_CODE
                        integer idx = (corr_sample_counter + corr_phase_counter * B1I_SAMPLES_PER_CHIP) % B1I_SAMPLES_PER_CODE;
                        
                        // Accumulate I and Q components
                        corr_real <= corr_real + mixed_signal_real[idx];
                        corr_imag <= corr_imag + mixed_signal_imag[idx];
                        
                        corr_sample_counter <= corr_sample_counter + 16'd1;
                    end else begin
                        // Correlation complete for this phase
                        // Calculate power = I² + Q²
                        correlation_results[corr_phase_counter] <= (corr_real * corr_real + corr_imag * corr_imag);
                        
                        // Move to next phase
                        corr_phase_counter <= corr_phase_counter + 16'd1;
                        corr_sample_counter <= 16'd0;
                    end
                end
                
                DONE: begin
                    // Hold state and results
                end
            endcase
        end
    end
    
    // Output ready signal
    assign search_ready = (state == DONE);

endmodule
