module wbck  (

  input [4:0]   i_alu_wb_idx,
  input         i_alu_wb_en,
  input [31:0]  i_alu_wb_dat,

  output [31:0] o_wbck_rdidx,
  output        o_wbck_wen,
  output [4:0]  o_wbck_wdat,

  input   clk   ,
  input   rst_n  
);


  assign  o_wbck_rdidx = i_alu_wb_idx;
  assign  o_wbck_wen  = i_alu_wb_en ;
  assign  o_wbck_wdat = i_alu_wb_dat;

endmodule