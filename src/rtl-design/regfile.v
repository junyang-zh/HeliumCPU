module regfile  (
  // 读寄存器接口
  input [4:0]  i_rf_rs1_idx,
  input [4:0]  i_rf_rs2_idx,
  // 写寄存器接口
  input        i_rf_wen,
  input [4:0]  i_rf_rdidx,
  input [31:0] i_rf_wdat,
  //读出的源操作数
  output [31:0] o_rf_rs1,
  output [31:0] o_rf_rs2,

  input   clk   ,
  input   rst_n  
);

// 寄存器文件，二维数组形式，每个32bit的数都表示一个寄存器，按照riscv-spec定义，总共有32个寄存器。
wire [31:0] rf_r[31:0];
// 一个具体的寄存器的实现，其他寄存器可按编号规律展开即可。
wire rf_wen_0 = i_rf_wen & (i_rf_rdidx == 0);
xf100_gnrl_dfflr #(32) reg0_dfflr (clk, rst_n, rf_wen_0, i_rf_wdat, rf_r[0]);

// 二维数组的直接输出
assign o_rf_rs1 = rf_r[i_rf_rs1_idx];
assign o_rf_rs2 = rf_r[i_rf_rs2_idx];

endmodule