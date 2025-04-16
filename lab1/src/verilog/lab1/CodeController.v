`timescale 1ns/1ps

module CodeController (
    input wire clk,
    input wire reset,
    input wire sync_flag,
    input wire [4:0] m_state_in,
    output reg [4:0] m_state_out
);
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            m_state_out <= m_state_in;
        end else begin
            if (!sync_flag) begin
                // 循环右移
                m_state_out <= {m_state_in[0], m_state_in[4:1]};
            end else begin
                m_state_out <= m_state_in;
            end
        end
    end
endmodule
