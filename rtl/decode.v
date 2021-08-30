`include "defines.v"

module inst_type (
    input [6:0] opcode,
    output reg [2:0] itype
);
    always @(*) case (opcode)
        `LUI,
        `AUIPC:     itype = `TYPE_U;
        `JAL:       itype = `TYPE_J;
        `BRANCH:    itype = `TYPE_B;
        `LOAD,
        `OP_IMM,
        `OP_IMM_32,
        `JALR,
        `MISC_MEM,
        `SYSTEM:    itype = `TYPE_I;
        `STORE:     itype = `TYPE_S;
        `OP,
        `OP_32:     itype = `TYPE_R;
        default:    itype = 0;
    endcase
endmodule

module imm_gen #(
    parameter XLEN = 32
)(
    input [31:0] inst,
    input [2:0] itype,
    output reg [XLEN - 1:0] imm
);
    always @(*) case (itype)
        `TYPE_I: imm = $signed(inst[31:20]);
        `TYPE_S: imm = $signed({inst[31:25], inst[11:7]});
        `TYPE_B: imm = $signed({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0});
        `TYPE_U: imm = $signed({inst[31:12], 12'b0});
        `TYPE_J: imm = $signed({inst[31], inst[19:12], inst[20], inst[30:21], 1'b0});
        default: imm = 0;
    endcase
endmodule

module decoder #(
    parameter XLEN = 32
)(
    input clock,
    input [31:0] inst,
    output [6:0] opcode,
    output [2:0] itype,
    output [2:0] funct3,
    output [6:0] funct7,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output [XLEN - 1:0] imm,
    output reg [4:0] alu_op,
    output s_pc,
    output s_imm,
    output s_jalr,
    output s_jump,
    output s_branch,
    output s_branch_zero,
    output s_load,
    output s_store,
    output s_32,
    output s_flush
);
    assign opcode = inst[6:0];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign rs1 = (itype == `TYPE_U || itype == `TYPE_J) ? 0 : inst[19:15];
    assign rs2 = (itype == `TYPE_I || itype == `TYPE_U || itype == `TYPE_J) ? 0 : inst[24:20];
    assign rd = (itype == `TYPE_S || itype == `TYPE_B) ? 0 : inst[11:7];

    assign s_jalr = opcode == `JALR && funct3 == 3'b0;
    assign s_jump = opcode == `JAL || s_jalr;
    assign s_pc = opcode == `AUIPC || opcode == `JAL;

    assign s_imm = !(opcode == `OP || opcode == `OP_32 || opcode == `BRANCH);
    assign s_branch = opcode == `BRANCH && (funct3 == `BEQ || funct3 == `BNE || funct3 == `BLT || funct3 == `BGE || funct3 == `BLTU || funct3 == `BGEU);
    assign s_branch_zero = opcode == `BRANCH && (funct3 == `BEQ || funct3 == `BGE || funct3 == `BGEU);

    assign s_load = opcode == `LOAD && (funct3 == `LB || funct3 == `LH || funct3 == `LW || funct3 == `LD || funct3 == `LBU || funct3 == `LHU || funct3 == `LWU);
    assign s_store = opcode == `STORE && (funct3 == `SB || funct3 == `SH || funct3 == `SW || funct3 == `SD);

    assign s_32 = opcode == `OP_32 || opcode == `OP_IMM_32;
    assign s_flush = opcode == `MISC_MEM;

    inst_type inst_type_inst (
        .opcode(opcode),
        .itype(itype)
    );

    imm_gen #(
    .XLEN(XLEN)
    )imm_gen_inst (
        .inst(inst),
        .itype(itype),
        .imm(imm)
    );

    always @(*) case (opcode)
        `LUI:       alu_op = `ALU_ADD;
        `OP_IMM: case (funct3)
            `ADDI:	alu_op = `ALU_ADD;
            `SLTI: 	alu_op = `ALU_CMP;
            `SLTIU:	alu_op = `ALU_UCMP;
            `ANDI: 	alu_op = `ALU_AND;
            `ORI:	alu_op = `ALU_OR;
            `XORI:	alu_op = `ALU_XOR;
            `SLLI:	alu_op = imm[11:6] == 6'b000000 ? `ALU_SLL : 0;
            `SRLI:	alu_op = imm[11:6] == 6'b000000 ? `ALU_SRL : imm[11:6] == 6'b010000 ? `ALU_SRA : 0;
            default:alu_op = 0;
        endcase
        `OP_IMM_32: case(funct3)
            `ADDIW:	alu_op = `ALU_ADD;
            `SLLIW: alu_op = imm[11:6] == 6'b000000 ? `ALU_SLL : 0;
            `SRLIW:	alu_op = imm[11:6] == 6'b000000 ? `ALU_SRL : imm[11:6] == 6'b010000 ? `ALU_SRA : 0;
            default:alu_op = 0;
        endcase
        `OP: case (funct7)
            7'b0000000: case (funct3)
                `ADD:	alu_op = `ALU_ADD;
                `SLT:	alu_op = `ALU_CMP;
                `SLTU:	alu_op = `ALU_UCMP;
                `AND:	alu_op = `ALU_AND;
                `OR:	alu_op = `ALU_OR;
                `XOR:	alu_op = `ALU_XOR;
                `SLL:	alu_op = `ALU_SLL;
                `SRL:	alu_op = `ALU_SRL;
                default:alu_op = 0;
            endcase
            7'b0100000: case (funct3)
                `SUB:   alu_op = `ALU_SUB;
                `SRA:   alu_op = `ALU_SRA;
                default:alu_op = 0;
            endcase
            7'b0000001: case (funct3)
                `MUL:   alu_op = `ALU_MUL;
                `MULH:  alu_op = `ALU_MULH;
                `MULHSU:alu_op = `ALU_MULHSU;
                `MULHU: alu_op = `ALU_MULHU;
                `DIV:   alu_op = `ALU_DIV;
                `DIVU:  alu_op = `ALU_DIVU;
                `REM:   alu_op = `ALU_REM;
                `REMU:  alu_op = `ALU_REMU;
                default:alu_op = 0;
            endcase
            default:alu_op = 0;
        endcase
        `OP_32: case (funct7)
            7'b0000000: case (funct3)
                `ADDW:	alu_op = `ALU_ADD;
                `SLLW:	alu_op = `ALU_SLL;
                `SRLW:	alu_op = `ALU_SRL;
                default:alu_op = 0;
            endcase
            7'b0100000: case (funct3)
                `SUBW:   alu_op = `ALU_SUB;
                `SRAW:   alu_op = `ALU_SRA;
                default:alu_op = 0;
            endcase
            7'b0000001: case (funct3)
                `MULW:   alu_op = `ALU_MUL;
                `DIVW:   alu_op = `ALU_DIV;
                `DIVUW:  alu_op = `ALU_DIVU;
                `REMW:   alu_op = `ALU_REM;
                `REMUW:  alu_op = `ALU_REMU;
                default:alu_op = 0;
            endcase
            default:alu_op = 0;
        endcase
        `BRANCH: case (funct3)
            `BEQ,
            `BNE:   alu_op = `ALU_SUB;
            `BLT,
            `BGE:   alu_op = `ALU_CMP;
            `BLTU,
            `BGEU:  alu_op = `ALU_UCMP;
            default:alu_op = 0;
        endcase
        default:    alu_op = (s_load || s_store || s_pc || s_jalr) ? `ALU_ADD : 0;
    endcase

endmodule
