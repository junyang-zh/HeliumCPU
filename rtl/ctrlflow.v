
module ctrl_flow #(
    parameter XLEN = 32,
    parameter [XLEN - 1:0] RESET = 0
)(
    input clock,
    input reset,
    input pause,
    input [XLEN - 1:0] nxt_pc,
    output reg [XLEN - 1:0] pc
);
	initial begin
		pc = 0;
	end

    always @(posedge clock) begin
        if (reset)
            pc <= RESET;
        else if (!pause)
            pc <= nxt_pc;
    end
endmodule

module fetch #(
    parameter XLEN = 32
)(
    input clock,
    input [XLEN - 1:0] pc,
    output ready,
    output [XLEN - 1:0] instruction
);
    gnr_ram imem(
        .clock(clock),
        .write_en(1'b0),
        .w_addr({XLEN{1'b0}}),
        .r_addr(pc),
        .ready(ready),
        .data_o(instruction)
    );
endmodule

module addr_gen #(
    parameter XLEN = 32
)(
    input alu_z,
    input s_jump,
    input s_jalr,
    input s_branch,
    input s_branch_zero,
    input [XLEN - 1:0] pc,
    input [XLEN - 1:0] ex_pc,
    input [XLEN - 1:0] imm,
    input [XLEN - 1:0] alu_o,
    output branch_take,
    output [XLEN - 1:0] nxt_pc
);
    assign branch_take = s_branch && (s_branch_zero ~^ alu_z);
    assign nxt_pc = s_jump ? (alu_o & ~s_jalr) : ((branch_take ? ex_pc : pc) + (branch_take ? imm : 4));
endmodule
