`timescale 1ns / 1ps

module acquisition_core (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire signed [3:0] signal_buffer [0:16367],  // Input signal samples
    input wire [10:0] prn,                            // PRN number to search for
    output wire acq_ready,                            // Indicates acquisition is complete
    output reg signal_detected,                       // Signal detection flag
    output reg [10:0] code_phase,                     // Detected code phase
    output reg [7:0] doppler_bin,                     // Detected doppler bin
    output reg [31:0] peak_metric,                    // Correlation peak value
    output reg [31:0] snr                             // Signal-to-noise ratio
);

    // Parameters
    parameter B1I_CODE_LENGTH = 2046;
    parameter B1I_SAMPLES_PER_CODE = 16368;
    parameter B1I_DOPPLER_RANGE = 10000;
    parameter B1I_DOPPLER_STEP = 500;
    parameter B1I_NUM_DOPPLER_BINS = 41; // (2*10000/500)+1
    parameter B1I_DETECTION_THRESHOLD = 32'h00180000; // 1.5 in fixed-point
    
    // State definitions
    localparam IDLE = 3'b000;
    localparam GENERATE_CODE = 3'b001;
    localparam GENERATE_CARRIER = 3'b010;
    localparam SEARCH_PHASE = 3'b011;
    localparam NEXT_DOPPLER = 3'b100;
    localparam CALCULATE_RESULT = 3'b101;
    localparam DONE = 3'b110;
    
    reg [2:0] state, next_state;
    
    // Signals for module control
    reg code_gen_start, carrier_gen_start, search_start;
    wire code_ready, carrier_ready, search_ready;
    
    // Doppler search variables
    reg signed [15:0] current_doppler_freq;
    reg [7:0] doppler_count;
    
    // Intermediate storage
    reg [2045:0] code_array;                      // PRN code chips
    reg signed [31:0] carrier_real [0:16367];     // Carrier I component
    reg signed [31:0] carrier_imag [0:16367];     // Carrier Q component
    reg [31:0] correlation_results [0:2045];      // Correlation for each code phase
    
    // Result tracking
    reg [31:0] max_correlation;
    reg [7:0] max_doppler_bin;
    reg [10:0] max_code_phase;
    reg [31:0] noise_floor;
    reg [15:0] noise_count;
    
    // Instantiate sub-modules
    generate_b1i_code code_gen (
        .clk(clk),
        .rst_n(rst_n),
        .start(code_gen_start),
        .prn(prn),
        .code_ready(code_ready),
        .code_array(code_array)
    );
    
    generate_carrier carrier_gen (
        .clk(clk),
        .rst_n(rst_n),
        .start(carrier_gen_start),
        .doppler_freq(current_doppler_freq),
        .carrier_ready(carrier_ready),
        .carrier_real(carrier_real),
        .carrier_imag(carrier_imag)
    );
    
    parallel_search phase_search (
        .clk(clk),
        .rst_n(rst_n),
        .start(search_start),
        .signal_samples(signal_buffer),
        .code_samples(code_array),
        .carrier_real(carrier_real),
        .carrier_imag(carrier_imag),
        .doppler_bin(doppler_count),
        .search_ready(search_ready),
        .correlation_results(correlation_results)
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
            IDLE: next_state = start ? GENERATE_CODE : IDLE;
            GENERATE_CODE: next_state = code_ready ? GENERATE_CARRIER : GENERATE_CODE;
            GENERATE_CARRIER: next_state = carrier_ready ? SEARCH_PHASE : GENERATE_CARRIER;
            SEARCH_PHASE: next_state = search_ready ? NEXT_DOPPLER : SEARCH_PHASE;
            NEXT_DOPPLER: next_state = (doppler_count >= B1I_NUM_DOPPLER_BINS-1) ? CALCULATE_RESULT : GENERATE_CARRIER;
            CALCULATE_RESULT: next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Control signals for sub-modules
    always @(*) begin
        code_gen_start = (state == GENERATE_CODE && !code_ready);
        carrier_gen_start = (state == GENERATE_CARRIER && !carrier_ready);
        search_start = (state == SEARCH_PHASE && !search_ready);
    end
    
    // Main acquisition process
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            doppler_count <= 8'd0;
            current_doppler_freq <= -B1I_DOPPLER_RANGE;
            max_correlation <= 32'd0;
            max_doppler_bin <= 8'd0;
            max_code_phase <= 11'd0;
            noise_floor <= 32'd0;
            noise_count <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    doppler_count <= 8'd0;
                    current_doppler_freq <= -B1I_DOPPLER_RANGE;
                    max_correlation <= 32'd0;
                    max_doppler_bin <= 8'd0;
                    max_code_phase <= 11'd0;
                    noise_floor <= 32'd0;
                    noise_count <= 16'd0;
                end
                
                SEARCH_PHASE: begin
                    if (search_ready) begin
                        // Find maximum correlation for this Doppler bin
                        for (integer phase = 0; phase < B1I_CODE_LENGTH; phase = phase + 1) begin
                            if (correlation_results[phase] > max_correlation) begin
                                max_correlation <= correlation_results[phase];
                                max_doppler_bin <= doppler_count;
                                max_code_phase <= phase;
                            end
                        end
                    end
                end
                
                NEXT_DOPPLER: begin
                    doppler_count <= doppler_count + 8'd1;
                    current_doppler_freq <= current_doppler_freq + B1I_DOPPLER_STEP;
                end
                
                CALCULATE_RESULT: begin
                    // Calculate noise floor (average of all correlation results excluding peak area)
                    noise_floor <= 32'd0;
                    noise_count <= 16'd0;
                    
                    for (integer phase = 0; phase < B1I_CODE_LENGTH; phase = phase + 1) begin
                        if (phase < (max_code_phase - 5) || phase > (max_code_phase + 5)) begin
                            noise_floor <= noise_floor + correlation_results[phase];
                            noise_count <= noise_count + 16'd1;
                        end
                    end
                    
                    // Final division to get average noise floor
                    // In real hardware this would be pipelined
                    if (noise_count > 0) begin
                        noise_floor <= noise_floor / noise_count;
                    end
                    
                    // Calculate SNR
                    if (noise_floor > 0) begin
                        snr <= max_correlation / noise_floor;
                    end else begin
                        snr <= 32'hFFFFFFFF; // Max value if division by zero
                    end
                    
                    // Set acquisition results
                    signal_detected <= (snr > B1I_DETECTION_THRESHOLD);
                    code_phase <= max_code_phase;
                    doppler_bin <= max_doppler_bin;
                    peak_metric <= max_correlation;
                end
                
                DONE: begin
                    // Results are ready
                end
            endcase
        end
    end
    
    // Output ready signal
    assign acq_ready = (state == DONE);

endmodule
