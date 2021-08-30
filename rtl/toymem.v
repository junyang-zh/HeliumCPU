module gnr_ram #(
	parameter WIDTH = 8,
	parameter DEPTH = 32,
    parameter DATAFILE = ""
)(
	input clock,
	input write_en,
    input [$clog2(DEPTH) - 1:0] w_addr,
	input [WIDTH - 1:0] data_i,
    input [$clog2(DEPTH) - 1:0] r_addr,
    output reg ready,
	output [WIDTH - 1:0] data_o
);
    reg [WIDTH - 1:0] words[DEPTH - 1:0];

    generate if (DATAFILE)
        initial begin
            $readmemh(DATAFILE, words);
        end
    endgenerate

    always @ (posedge clock) begin
        data_o <= words[r_addr];
        ready <= 1'b1;
		if (write_en)
            words[w_addr] <= data_i;
    end
endmodule