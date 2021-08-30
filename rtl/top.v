
module top(
    input clock,
    input reset
);

`ifdef XLEN
localparam XLEN = `XLEN;
`else
localparam XLEN = 32;
`endif

    cpu #(
        .XLEN(XLEN)
    ) cpu_inst (
        .clock(clock),
        .reset(reset),
    );

endmodule