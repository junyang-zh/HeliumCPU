module top(
  input clk,
  input rst,
  output err
);

assign err = clk ^ rst;

endmodule