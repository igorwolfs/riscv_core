`timescale 1ns/10ps
`include "define.vh"


module core_cbranch (
	// FUNCT3 DATA
	input [2:0] FUNCT3,
	// REGISTERS
	input [31:0] REG_RDATA1,
	input [31:0] REG_RDATA2,
	// ISBRANCH
	output ISBRANCH
);

	always @(*)
	begin
		case (FUNCT3)
			`FUNCT3_BEQ:
				
			`FUNCT3_BEQ:
			`FUNCT3_BNE:
			`FUNCT3_BLT:
			`FUNCT3_BGE:
			`FUNCT3_BLTU:
			`FUNCT3_BGEU:
			
		endcase
	end


endmodule

/**
ARGUMENTS
- Input: funct3
- outputs: 2 register values
- inputs: 2 data values from register
- checks branch condition
- outputs isbranch-signal

*/