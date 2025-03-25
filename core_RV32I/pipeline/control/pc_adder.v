module pc_adder(
	input [31:0] ARG_I1,
	input [31:0] ARG_I2,
	output [31:0] ARG_O
);

assign ARG_O = ARG_I1+ARG_I2;

endmodule
