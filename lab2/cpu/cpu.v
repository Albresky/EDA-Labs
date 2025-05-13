`timescale 1ns / 1ns

module cpu (
    rst_,
    clock,
    rd,
    wr,
    data_in,
    data_out,
    addr
);
    input  rst_;
    input  clock;
    output rd;
    output wr;
    output [7:0] data_in;
    reg    [7:0] data_in;
    input  [7:0] data_out;
    output [4:0] addr;
    
    // Internal signals
    wire [7:0] alu_out;
    wire [7:0] ir_out;
    wire [7:0] ac_out;
    wire [4:0] pc_addr;
    wire [4:0] ir_addr;
    wire [2:0] opcode;

    // Extract instruction fields
    assign opcode  = ir_out[7:5];
    assign ir_addr = ir_out[4:0];
    
    // Control unit
    control ctl1 (
        .rd     (rd),
        .wr     (wr),
        .ld_ir  (ld_ir),
        .ld_ac  (ld_ac),
        .ld_pc  (ld_pc),
        .inc_pc (inc_pc),
        .halt   (halt),
        .data_e (data_e),
        .sel    (sel),
        .opcode (opcode),
        .zero   (zero),
        .clk    (clock),
        .rst_   (rst_)
    );
    
    // ALU
    alu alu1 (
        .out    (alu_out),
        .zero   (zero),
        .opcode (opcode),
        .data   (data_out),
        .accum  (ac_out)
    );
    
    // Accumulator register
    register ac (
        .out  (ac_out),
        .data (alu_out),
        .load (ld_ac),
        .clk  (clock),
        .rst_ (rst_)
    );
    
    // Instruction register
    register ir (
        .out  (ir_out),
        .data (data_out),
        .load (ld_ir),
        .clk  (clock),
        .rst_ (rst_)
    );
    
    // Address multiplexer
    scale_mux #5 smx (
        .out (addr),
        .sel (sel),
        .b   (pc_addr),
        .a   (ir_addr)
    );
    
    // Program counter
    counter pc (
        .cnt  (pc_addr),
        .data (ir_addr),
        .load (ld_pc),
        .clk  (inc_pc),
        .rst_ (rst_)
    );
    
    // Data input multiplexing
    always @(*) 
        data_in = (data_e) ? alu_out : 8'bz;
endmodule
