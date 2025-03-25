`timescale 1ns / 10ps

module core_cpc_update (
	input [31:0] IMM,
	input [31:0] REG_RDATA1,
	input C_TAKE_BRANCH,
	input ISJAL,
	input ISJALR,
	input [31:0] PC,
	input [31:0] IDEX_PC,
	output [31:0] PC_NEXT
);


wire [31:0] arg_i1, arg_i2;

assign arg_i1 = (C_TAKE_BRANCH | ISJAL) ? IDEX_PC :
				ISJALR ? REG_RDATA1 :
				PC;

assign arg_i2 = (C_TAKE_BRANCH | ISJAL) ? IDEX_PC :
				ISJALR ? IMM :
				4;
				
pc_adder pc_adder_inst (
	.ARG_I1(arg_i1),
	.ARG_I2(arg_i2),
	.ARG_O(PC_NEXT)
);

endmodule
