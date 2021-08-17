module top(
  input logic clk,
  input logic rst,
  output logic error
);

assign error = clk ^ rst;

endmodule