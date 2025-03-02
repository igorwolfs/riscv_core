`timescale 1ns/10ps

module single_ff #(parameter WIDTH=32, parameter NRST_VAL = 0)
(
    input CLK,
    input NRST,
    input [WIDTH-1:0] D,
    output reg [WIDTH-1:0] Q
);

always @(posedge CLK)
begin
    if (~NRST)
        Q <= NRST_VAL;
    else
        Q <= D;
end

endmodule
