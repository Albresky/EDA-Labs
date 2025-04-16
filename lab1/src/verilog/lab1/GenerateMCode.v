`timescale 1ns/1ps

module GenerateMCode (
    input wire clk,
    input wire reset,
    input wire [4:0] init_state,
    output reg m_code,
    output reg [4:0] state
);
    
    // M序列生成器 - 反馈多项式：x^5 + x^3 +1
    wire feedback;
    assign feedback = state[4] ^ state[2];
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= init_state;
            m_code <= 0;
        end else begin
            state <= {state[3:0], feedback};
            m_code <= state[0];
        end
    end
endmodule
