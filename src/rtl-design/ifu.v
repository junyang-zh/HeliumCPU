module ifu  (
  output         valid,
  input          ready,
  output [31:0]  pc,
  output [31:0]  instr,

  output         ifu2ram_cs,  
  output         ifu2ram_w_en, 
  output [14:0]  ifu2ram_addr, 
  input  [31:0]  ifu2ram_din, 

  input   clk,
  input   rst 
);

wire ifu_exu_valid;
xf100_gnrl_dfflr #(1) ifu_valid_dfflr (clk, rst_n, 1'b1, 1'b1, ifu_exu_valid);

`define RST_PC 32'h80000000
reg [31:0] ifu_pc;

wire ifu_upena = o_ifu_exu_valid & o_ifu_exu_ready;

wire [31:0] ifu_pc_nxt = ifu_pc + 32'h4;

always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        ifu_pc <= `RST_PC;
    end else if(ifu_upena) begin
        ifu_pc <= ifu_pc_nxt;
    end
end

assign o_ifu_exu_valid = ifu_exu_valid;
assign o_ifu_exu_pc = ifu_pc;
assign o_ifu_exu_instr = ifu2ram_din;


assign ifu2ram_cs  = 1'b1 & o_ifu_exu_ready; 
assign ifu2ram_wen = 1'b0;
assign ifu2ram_addr = ifu_pc;

endmodule