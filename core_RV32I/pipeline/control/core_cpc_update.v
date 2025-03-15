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

assign PC_NEXT = (C_TAKE_BRANCH | ISJAL) ? (IDEX_PC + IMM) :
				(ISJALR) ? (REG_RDATA1 + IMM) :
				(PC+4);

endmodule

/***
Check
- ISJAL
- ISJALR
- BRANCH_TAKEN
- PC
Depending on all these factors
- Compare the program counter
*/

/**
The C_WHATEVER commands come in at the clock edge.
- The REG_RDATA1
- 
*/