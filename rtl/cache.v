
module cache #(
    parameter XLEN = 32,
    parameter NWAYS = 8,
    parameter LINE_SIZE = 64,
    parameter SIZE = 512
)(
    input clock,
    input mem_write_en,
    input cpu_write_en,
    input [XLEN - 1:0] address,
    input [8 * LINE_SIZE - 1:0] data_in,
    output reg [8 * LINE_SIZE - 1:0] data_out,
    output hit
);
    // TODO: implement cache and its replace algorithm
endmodule
