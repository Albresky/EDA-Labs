// cpu.v
`timescale 1 ns / 1 ns

module cpu (
    input          rst_,
    input          clock,
    output         rd,
    output         wr,
    output [7:0]   data_in,
    input  [7:0]   data_out,
    output [4:0]   addr,
    output         halt
);

  // --- 中间信号声明 ---
  wire        ld_ir, ld_ac, ld_pc, inc_pc;
  wire        data_e, sel, zero;
  wire [2:0]  opcode;
  wire [4:0]  ir_addr, pc_addr;
  wire [7:0]  ir_out, ac_out, alu_out;

  // 指令寄存器高 3 位是 opcode，低 5 位是地址
  assign opcode  = ir_out[7:5];
  assign ir_addr = ir_out[4:0];
  assign addr    = pc_addr;    // 取址信号最终由 PC 输出

  // 控制单元
  control ctl1 (
    .clk    (clock),
    .rst_   (rst_),
    .zero   (zero),
    .opcode (opcode),
    .sel    (sel),
    .rd     (rd),
    .wr     (wr),
    .ld_ir  (ld_ir),
    .ld_ac  (ld_ac),
    .ld_pc  (ld_pc),
    .inc_pc (inc_pc),
    .halt   (halt),
    .data_e (data_e)
  );

  // 算术逻辑单元
  alu alu1 (
    .out    (alu_out),
    .zero   (zero),
    .opcode (opcode),
    .data   (data_out),
    .accum  (ac_out)
  );

  // 累加器寄存器
  register ac (
    .clk   (clock),
    .rst_  (rst_),
    .load  (ld_ac),
    .data  (alu_out),
    .out   (ac_out)
  );

  // 指令寄存器
  register ir (
    .clk   (clock),
    .rst_  (rst_),
    .load  (ld_ir),
    .data  (data_out),
    .out   (ir_out)
  );

  // 地址多路选择器
  scale_mux #(.WIDTH(5)) smx (
    .sel (sel),
    .a   (ir_addr),
    .b   (pc_addr),
    .out (addr)
  );

  // 程序计数器
  counter pc (
    .clk   (inc_pc),
    .rst_  (rst_),
    .load  (ld_pc),
    .data  (ir_addr),
    .cnt   (pc_addr)
  );

  // 数据总线驱动：高阻或累加器输出
  reg [7:0] data_in_reg;
  always @(*) begin
    if (data_e)
      data_in_reg = alu_out;
    else
      data_in_reg = 8'bz;
  end
  assign data_in = data_in_reg;

endmodule
