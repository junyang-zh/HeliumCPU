
module wbu #(
	parameter XLEN = 32,
	parameter NUM = 32
)(
	input clock,
	input [$clog2(NUM) - 1:0] addr_w,
	input [$clog2(NUM) - 1:0] addr_r1,
	input [$clog2(NUM) - 1:0] addr_r2,
	input [XLEN - 1:0] data_w,
	output [XLEN - 1:0] data_r1,
	output [XLEN - 1:0] data_r2
);
    // TODO: stage WB 
endmodule
