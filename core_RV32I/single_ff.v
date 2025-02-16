module single_ff #(parameter WIDTH=32, parameter NRST_VAL = 0)
(
    input clkin,
    input nrst_in,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

always @(posedge clkin)
begin
    if (~nrst_in)
        data_in <= NRST_VAL;
    else
        data_out <= data_in;
end

endmodule
