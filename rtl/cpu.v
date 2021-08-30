`include "defines.v"

module cpu #(
	parameter XLEN = 32
)(
	input clock,
	input reset,
);

    // mem interface
	wire [XLEN - 1:0] address;
	wire mem_load;
	wire [XLEN - 1:0] load_data;
	wire mem_store;
	wire [XLEN - 1:0] store_data;
	wire [XLEN - 1:0] pc;
	wire [31:0] inst;
    wire [2:0] itype;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    
    // IF_ID
    wire [XLEN - 1:0] id_pc, ex_pc, mem_pc;				// used by alu
    wire [31:0] instruction_if, instruction_id;			// used by decode
    wire if_ready;                                      // used by fetch
    
    // ID_EX		
    wire [4:0] rd, ex_rd, mem_rd, wb_rd;				// used by stage WB
    wire [4:0] rs1, rs2;								// used by wbu
    wire [XLEN - 1:0] id_rs1, ex_rs1, id_rs2, ex_rs2;	// used by forward
    wire [XLEN - 1:0] id_imm, ex_imm, mem_imm;			// used by alu
    wire [4:0] ex_rs1_fw, ex_rs2_fw;					// used by forward
    
    // EX_MEM
    wire [XLEN - 1:0] mem_rs1, mem_rs2;					// store data
    wire [XLEN - 1:0] mem_alu;							// store/load address
    
    // MEM_WB
    wire [XLEN - 1:0] wb_alu;							// write back to gpr
    
    // control EX	
    wire [4:0] id_alu_op, ex_alu_op;					// used by alu
    wire s_pc, ex_s_pc, s_imm, ex_s_imm, s_32, ex_s_32; // used by alu
    wire s_jalr, s_jump, s_branch, s_branch_zero;		// used by addr_gen
    wire ex_jalr, ex_jump, ex_branch, ex_branch_zero;	// used by addr_gen
    
    // control MEM
    wire s_store, ex_store, s_load, ex_load;
    wire [2:0] ex_funct3, mem_funct3;
    
    // control pipe
    wire if_id_pause, id_ex_pause, ex_mem_pause, mem_wb_pause; 
    wire if_id_bubble, id_ex_bubble, ex_mem_bubble, mem_wb_bubble;
    
    // stage IF
    wire pc_pause;
    wire [XLEN - 1:0] nxt_pc;
    
    ctrl_flow #(
        .XLEN(XLEN)
    ) ctrl_flow_inst(
        .clock(clock),
        .reset(reset),
        .pause(pc_pause),
        .nxt_pc(nxt_pc),
        .pc(pc)
    );
    
    fetch fetch_inst(
        .clock(clock),
        .pc(pc),
        .ready(if_ready),
        .instruction(inst)
    );

    if_id #(
        .XLEN(XLEN)
    ) if_id_inst (
        .clock(clock),
        .pause(if_id_pause),
        .bubble(if_id_bubble),
        .pc_in(pc),
        .inst_in(inst),
        .pc_out(id_pc),
        .inst_out(instruction_if)
    );
    
    // stage ID
    wire branch_take;
    hazard hazard_inst(
        .if_wait(if_ready),
        .ex_jump(branch_take || ex_jump),
        .ex_load(ex_load),
        .ex_rd(ex_rd),
        .rs1(rs1),
        .rs2(rs2),
        .pc_pause(pc_pause),
        .pipe_pause({if_id_pause, id_ex_pause, ex_mem_pause, mem_wb_pause}),
        .pipe_bubble({if_id_bubble, id_ex_bubble, ex_mem_bubble, mem_wb_bubble})
    );
    
    assign instruction_id = instruction_if;
    
    decoder #(
        .XLEN(XLEN)
    ) decoder_inst (
        .clock(clock),
        .inst(instruction_id),
        .opcode(opcode),
        .itype(itype),
        .funct3(funct3),
        .funct7(funct7),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(id_imm),
        .alu_op(id_alu_op),
        .s_pc(s_pc),
        .s_imm(s_imm),
        .s_jalr(s_jalr),
        .s_jump(s_jump),
        .s_branch(s_branch),
        .s_branch_zero(s_branch_zero),
        .s_load(s_load),
        .s_store(s_store),
        .s_32(s_32),
    );
    
    id_ex #(
        .XLEN(XLEN)
    ) id_ex_inst (
        .clock(clock),
        .pause(id_ex_pause),
        .bubble(id_ex_bubble),
        .rd_in(rd),
        .rs1_fw_in(rs1),
        .rs2_fw_in(rs2),
        .pc_in(id_pc),
        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .imm_in(id_imm),
        // width  5          1     1      1     1       1         1              1       1        1       1       = 15
        .ctrl_in({id_alu_op, s_pc, s_imm, s_32, s_jalr, s_branch, s_branch_zero, s_jump, s_store, s_load, funct3}),
        .rd_out(ex_rd),
        .rs1_fw_out(ex_rs1_fw),
        .rs2_fw_out(ex_rs2_fw),
        .pc_out(ex_pc),
        .rs1_out(ex_rs1),
        .rs2_out(ex_rs2),	
        .imm_out(ex_imm),
        .ctrl_out({ex_alu_op, ex_s_pc, ex_s_imm, ex_s_32, ex_jalr, ex_branch, ex_branch_zero, ex_jump, ex_store, ex_load, ex_funct3})
    );
    
    // stage EX
    wire [XLEN - 1:0] f_rs1, f_rs2;
    forward #(
        .XLEN(XLEN)
    ) forward_inst (
        .mem_rd(mem_rd),
        .wb_rd(wb_rd),
        .rs1(ex_rs1_fw),
        .rs2(ex_rs2_fw),
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .mem_rd_reg(mem_alu),
        .wb_rd_reg(wb_alu),
        .rs1_reg(f_rs1),
        .rs2_reg(f_rs2)
    );
    
    wire alu_z;
    wire [XLEN - 1:0] alu_o;
    wire [XLEN - 1:0] mul_o, div_o;
    
    alu #(
        .XLEN(XLEN)
    ) alu_inst(
        .s_32(ex_s_32),
        .opcode(ex_alu_op),
        .rs1(ex_s_pc? ex_pc : f_rs1),
        .rs2(ex_s_imm ? ex_imm : f_rs2),
        .rd(alu_o),
        .zero(alu_z)
    );
    
    wire [XLEN - 1:0] ex_alu;
    
    addr_gen #(
        .XLEN(XLEN)
    ) addr_gen_inst (
        .alu_z(alu_z),
        .s_jump(ex_jump),
        .s_jalr(ex_jalr),
        .s_branch(ex_branch),
        .s_branch_zero(ex_branch_zero),
        .pc(pc),
        .ex_pc(ex_pc),
        .imm(ex_imm),
        .alu_o(alu_o),
        .branch_take(branch_take),
        .nxt_pc(nxt_pc)
    );
    
    ex_mem #(
        .XLEN(XLEN)
    ) ex_mem_inst (
        .clock(clock),
        .pause(ex_mem_pause),
        .bubble(ex_mem_bubble),
        .rd_in(ex_rd),
        .rs2_in(f_rs2),
        .alu_in(ex_alu),
        .ctrl_in({ex_store, ex_load, ex_funct3}),
        .rd_out(mem_rd),
        .rs2_out(mem_rs2),
        .alu_out(mem_alu),
        .ctrl_out({mem_store, mem_load, mem_funct3})
    );
    
    // stage MEM
    assign address = mem_alu;
    
    wire [XLEN - 1:0] mem_data;
    lu #(
        .XLEN(XLEN)
    ) lu_inst(
        .s_byte(address[0]),
        .funct3(mem_funct3),
        .data_in(load_data),
        .data_out(mem_data)
    );
    
    su #(
        .XLEN(XLEN)
    ) su_inst(
        .s_byte(address[0]),
        .funct3(mem_funct3),
        .data_l(load_data),
        .data_in(mem_rs2),
        .data_out(store_data)
    );
    
    wire [XLEN - 1:0] mem_rd_reg = mem_load ? mem_data : mem_alu;
    mem_wb #(
        .XLEN(XLEN)
    ) mem_wb_inst (
        .clock(clock),
        .pause(mem_wb_pause),
        .bubble(mem_wb_bubble),
        .rd_in(mem_rd),
        .alu_in(mem_rd_reg),
        .rd_out(wb_rd),
        .alu_out(wb_alu)
    );
    
    // stage WB
    wbu #(
        .XLEN(XLEN)
    ) wbu_inst (
        .clock(clock),
        .addr_w(wb_rd),
        .addr_r1(rs1),
        .addr_r2(rs2),
        .data_w(wb_alu),
        .data_r1(id_rs1),
        .data_r2(id_rs2)
    );
    
endmodule
