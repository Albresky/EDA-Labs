`timescale 1ns / 1ps

module generate_b1i_code (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [10:0] prn,
    output wire code_ready,
    output reg [2045:0] code_array
);

    // State definitions
    localparam IDLE = 2'b00;
    localparam GENERATING = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [10:0] g1_state, g2_state;
    reg [10:0] counter;
    reg [10:0] phase_selector;
    
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
            GENERATING: next_state = (counter == 11'd2045) ? DONE : GENERATING;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Code generation process - implements the G1 and G2 feedback shift registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g1_state <= 11'h001;  // Initial state for G1 register
            g2_state <= 11'h001;  // Initial state for G2 register
            counter <= 11'd0;
            phase_selector <= 11'd0;
            code_array <= 2046'd0;
        end else begin
            case (state)
                IDLE: begin
                    g1_state <= 11'h001;  // Initial state for G1 register
                    g2_state <= 11'h001;  // Initial state for G2 register
                    counter <= 11'd0;
                    phase_selector <= prn;  // Phase selection based on PRN
                end
                
                GENERATING: begin
                    // G1 feedback: X11 + X9 + X8 + X6 + X3 + X + 1
                    // g1_feedback = g1_state[10] ^ g1_state[8] ^ g1_state[7] ^ g1_state[5] ^ g1_state[2] ^ g1_state[0]
                    g1_state <= {g1_state[10] ^ g1_state[8] ^ g1_state[7] ^ g1_state[5] ^ g1_state[2] ^ g1_state[0], g1_state[10:1]};
                    
                    // G2 feedback: X11 + X10 + X9 + X8 + X6 + X5 + X4 + X2 + 1
                    // g2_feedback = g2_state[10] ^ g2_state[9] ^ g2_state[8] ^ g2_state[7] ^ g2_state[5] ^ g2_state[4] ^ g2_state[3] ^ g2_state[1]
                    g2_state <= {g2_state[10] ^ g2_state[9] ^ g2_state[8] ^ g2_state[7] ^ g2_state[5] ^ g2_state[4] ^ g2_state[3] ^ g2_state[1], g2_state[10:1]};
                    
                    // B1I code is G1 XOR G2, with G2 tapped according to PRN specific phase
                    code_array[counter] <= g1_state[0] ^ g2_state[phase_selector % 11];
                    
                    // Increment counter
                    counter <= counter + 11'd1;
                end
                
                DONE: begin
                    // Hold state and results
                end
            endcase
        end
    end
    
    // Output ready signal
    assign code_ready = (state == DONE);

endmodule
