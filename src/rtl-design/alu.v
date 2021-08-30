module alu  (

  input [4:0]  i_alu_rd_idx,
  input        i_alu_rd_wen,

  input [31:0] i_alu_rs1,
  input [31:0] i_alu_rs2,

  input  i_add_op,

  output [31:0] o_alu_wdat,
  output [4:0]  o_alu_rd_idx,
  output        o_alu_rd_wen,

  input   clk   ,
  input   rst_n  
);


wire [31:0] adder_rs1 = {32{i_add_op}} & i_alu_rs1;
wire [32:0] adder_rs2 = {32{i_add_op}} & i_alu_rs2;


assign o_alu_wdat = adder_rs1 + adder_rs2;

assign o_alu_rd_idx = i_alu_rd_idx;
assign o_alu_rd_wen = i_alu_rd_wen;


endmodule