// D-flip-flop with rst and load en
module d_ff #(
    parameter WIDTH = 8;
) (
    input clk,
    input rst,
    input ld_en,

    input [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);

reg [WIDTH-1:0] r_out;
always @(posedge clk or negedge rst) begin
    if (~rst) begin
        r_out <= WIDTH'b0;
    end
    else if (ld_en) begin
        r_out <= in;
    end
end
assign out = r_out;

endmodule

// a toy 4096B RAM
module toy_ram #(
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 16;
    parameter ADDR_GRANU = 8;
    parameter SIZE = 16384;
) (
    input clk,
    input rst,

    input write,
    input [DATA_WIDTH-1:0] dat_in,

    input read,
    input [ADDR_WIDTH-1:0] addr,

    output available,
    output [DATA_WIDTH-1:0] dat_out,

    output conflict_err
);

wire [ADDR_GRANU-1:0] d_ff_in[SIZE-1:0], d_ff_out[SIZE-1:0], write_en;

genvar i
generate
    for (i = 0; i < SIZE; i = i + 1) begin
        d_ff d_ff_i #(ADDR_GRANU) (.clk(clk), .rst(rst), ld_en(write_en[i]), .in(d_ff_in[i]), .out(d_ff_out[i]));
    end
endgenerate

if (write) begin
    assign d_ff_in[addr+0] = dat_in[07:00];
    assign d_ff_in[addr+1] = dat_in[15:08];
    assign d_ff_in[addr+2] = dat_in[23:16];
    assign d_ff_in[addr+3] = dat_in[31:24];
    assign write_en[addr+0] = 1'b0, write_en[addr+1] = 1'b0, write_en[addr+2] = 1'b0, write_en[addr+3] = 1'b0;
end

assign dat_out [07:00] = d_ff_out[addr+0] & {DW{read}};
assign dat_out [15:08] = d_ff_out[addr+1] & {DW{read}};
assign dat_out [23:16] = d_ff_out[addr+2] & {DW{read}};
assign dat_out [31:24] = d_ff_out[addr+3] & {DW{read}};
    
endmodule