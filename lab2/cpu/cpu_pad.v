// cpu_pad.v
`timescale 1 ns / 1 ns

module cpu_pad (
    input          rst_,
    input          clock,
    output         rd,
    output         wr,
    output [7:0]   data_in,
    input  [7:0]   data_out,
    output [4:0]   addr,
    output         halt
);

  // wrapper 内部信号
  wire rst_pad;
  wire clock_pad;
  wire rd_pad;
  wire wr_pad;
  wire [7:0] data_in_pad;
  wire [7:0] data_out_pad;
  wire [4:0] addr_pad;
  wire halt_pad;

  // Input ports
  PI i_rst (.PAD(rst_), .C(rst_pad));
  PI i_clock (.PAD(clock), .C(clock_pad));
  PI i_data_out_0 (.PAD(data_out[0]), .C(data_out_pad[0]));
  PI i_data_out_1 (.PAD(data_out[1]), .C(data_out_pad[1]));
  PI i_data_out_2 (.PAD(data_out[2]), .C(data_out_pad[2]));
  PI i_data_out_3 (.PAD(data_out[3]), .C(data_out_pad[3]));
  PI i_data_out_4 (.PAD(data_out[4]), .C(data_out_pad[4]));
  PI i_data_out_5 (.PAD(data_out[5]), .C(data_out_pad[5]));
  PI i_data_out_6 (.PAD(data_out[6]), .C(data_out_pad[6]));
  PI i_data_out_7 (.PAD(data_out[7]), .C(data_out_pad[7]));

  // Output ports
  PO8 i_rd (.I(rd_pad), .PAD(rd));
  PO8 i_wr (.I(wr_pad), .PAD(wr));
  PO8 i_data_in_0 (.I(data_in_pad[0]), .PAD(data_in[0]));
  PO8 i_data_in_1 (.I(data_in_pad[1]), .PAD(data_in[1]));
  PO8 i_data_in_2 (.I(data_in_pad[2]), .PAD(data_in[2]));
  PO8 i_data_in_3 (.I(data_in_pad[3]), .PAD(data_in[3]));
  PO8 i_data_in_4 (.I(data_in_pad[4]), .PAD(data_in[4]));
  PO8 i_data_in_5 (.I(data_in_pad[5]), .PAD(data_in[5]));
  PO8 i_data_in_6 (.I(data_in_pad[6]), .PAD(data_in[6]));
  PO8 i_data_in_7 (.I(data_in_pad[7]), .PAD(data_in[7]));
  PO8 i_addr_0 (.I(addr_pad[0]), .PAD(addr[0]));
  PO8 i_addr_1 (.I(addr_pad[1]), .PAD(addr[1]));
  PO8 i_addr_2 (.I(addr_pad[2]), .PAD(addr[2]));
  PO8 i_addr_3 (.I(addr_pad[3]), .PAD(addr[3]));
  PO8 i_addr_4 (.I(addr_pad[4]), .PAD(addr[4]));
  PO8 i_halt (.I(halt_pad), .PAD(halt));

  // 实例化 cpu
  cpu i_cpu (
    .rst_     (rst_pad),
    .clock    (clock_pad),
    .rd       (rd_pad),
    .wr       (wr_pad),
    .data_in  (data_in_pad),
    .data_out (data_out_pad),
    .addr     (addr_pad),
    .halt     (halt_pad)
  );

endmodule
