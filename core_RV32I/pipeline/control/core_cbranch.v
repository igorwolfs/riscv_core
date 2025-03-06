`timescale 1ns/10ps
`include "define.vh"


module core_cbranch (
	input 		NRST,
	input 		CLK,
	input 		C_BRANCH,
	// FUNCT3 DATA
	input [2:0] FUNCT3,
	// REGISTERS (assuming the correct register values are fetched)
	input [31:0] REG_RDATA1,
	input [31:0] REG_RDATA2,
	// ISBRANCH
	output reg TAKE_BRANCH
);

// * Branching conditions
wire br_eq, br_ne, br_blt, br_bge, br_bltu, br_bgeu, br_cond;

// Make sure to check additional branch condition
assign br_eq = (REG_RDATA1 == REG_RDATA2);
assign br_ne = !br_eq;

// Numbers in verilog are signed by default
assign br_blt = ($signed(REG_RDATA1) < $signed(REG_RDATA2));
assign br_bge = !br_blt;

// Unsigned
assign br_bltu = ($unsigned(REG_RDATA1) < $unsigned(REG_RDATA2));
assign br_bgeu = !br_bltu;

// * Check if the branching condition is fulfilled
assign take_branch = ((`FUNCT3_BEQ == FUNCT3) && (br_eq))
                    || ((`FUNCT3_BNE == FUNCT3) && (br_ne))
                    || ((`FUNCT3_BLT == FUNCT3) && (br_blt))
                    || ((`FUNCT3_BGE == FUNCT3) && (br_bge))
                    || ((`FUNCT3_BLTU == FUNCT3) && (br_bltu))
                    || ((`FUNCT3_BGEU == FUNCT3) && (br_bgeu));
always @(posedge CLK)
begin
	if (~NRST)
		TAKE_BRANCH <= 0;
	else if (C_BRANCH)
		TAKE_BRANCH <= take_branch;
	else;
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