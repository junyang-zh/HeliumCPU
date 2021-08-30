
module hazard(
    input if_wait,
    input ex_jump,
    input ex_load,
    input [4:0] ex_rd,
    input [4:0] rs1,
    input [4:0] rs2,
    output pc_pause,
    output [3:0] pipe_pause,
    output [3:0] pipe_bubble
);
    localparam PIPE_IF_ID = 4'b1000;
    localparam PIPE_ID_EX = 4'b0100;
    localparam PIPE_EX_MEM = 4'b0010;

    wire load_hazard = ex_load && ((ex_rd == rs1) || (ex_rd == rs2));

    assign pc_pause = load_hazard;
    assign pipe_pause = load_hazard ? PIPE_IF_ID : 0;
    assign pipe_bubble = if_wait ? PIPE_IF_ID :
                        load_hazard ? PIPE_ID_EX :
                        ex_jump ? (PIPE_IF_ID | PIPE_ID_EX) : 0;
endmodule
