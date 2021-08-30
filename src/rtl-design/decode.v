module decode  (
  
  input [31:0]  i_dec_pc,
  input [31:0]  i_dec_instr,

  output        o_dec_add,
  output [4:0]  o_dec_rs1_idx,
  output [4:0]  o_dec_rs2_idx,
  output [4:0]  o_dec_rd_idx,
  output        o_dec_rd_wen 
);


wire add_op = (i_dec_instr[6:0]   == 7'b0110011) 
            & (i_dec_instr[14:12] == 3'b000)
            & (i_dec_instr[31:25] == 7'b0000000)
            ; 

wire [4:0] rs1_idx = i_dec_instr[19:15];
wire [4:0] rs2_idx = i_dec_instr[24:20];
wire [4:0] rd_idx  = i_dec_instr[11:7];


assign  o_dec_add     = add_op;
assign  o_dec_rs1_idx = rs1_idx;
assign  o_dec_rs2_idx = rs2_idx;
assign  o_dec_rd_idx  = rd_idx ; 
assign  o_dec_rd_wen  = add_op;

endmodule