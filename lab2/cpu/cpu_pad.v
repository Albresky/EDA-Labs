// cpu_pad.v
`timescale 1 ns / 1 ns

module cpu_pad (
    input          rst_,
    input          clock,
    output         rd,
    output         wr,
    output         halt,
    inout  [7:0]   data_in,
    input  [7:0]   data_out,
    output [4:0]   addr
);

  // wrapper 内部信号
  wire rd_pad, wr_pad, halt_pad;
  wire [7:0] data_in_pad;

  // 实例化 cpu
  cpu i_cpu (
    .rst_     (rst_),
    .clock    (clock),
    .rd       (rd_pad),
    .wr       (wr_pad),
    .data_in  (data_in_pad),
    .data_out (data_out),
    .addr     (addr),
    .halt     (halt_pad)
  );

  // 总线与 wrapper 端口映射
  assign rd      = rd_pad;
  assign wr      = wr_pad;
  assign halt    = halt_pad;
  assign data_in = data_in_pad;

endmodule
