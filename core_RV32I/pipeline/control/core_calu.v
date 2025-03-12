`timescale 1ns/10ps
`include "define.vh"

module core_calu (
	input [6:0] 		OPCODE,
	input [2:0] 		FUNCT3,
	input [6:0] 		FUNCT7,
	input [31:0] 		IMM,
	input				ISIMM,
	// REGISTER READ / WRITES
	output [3:0]		OPCODE_ALU
);
	assign OPCODE_ALU = ((FUNCT3 == `FUNCT3_ADD) & (!FUNCT7[5] | ISIMM)) ? `ALU_CODE_ADD :
						((FUNCT3 == `FUNCT3_ADD) & (FUNCT7[5] & !ISIMM)) ? `ALU_CODE_SUB :
						(FUNCT3 == `FUNCT3_XOR) ? `ALU_CODE_XOR :
						(FUNCT3 == `FUNCT3_OR) ? `ALU_CODE_OR :
						(FUNCT3 == `FUNCT3_AND) ? `ALU_CODE_AND :
						 (FUNCT3 == `FUNCT3_SLL) ? `ALU_CODE_SLL :
						 ((FUNCT3 == `FUNCT3_SR) & (!FUNCT7[5])) ? `ALU_CODE_SRL :
						 ((FUNCT3 == `FUNCT3_SR) & (FUNCT7[5])) ? `ALU_CODE_SRA :
						 (FUNCT3 == `FUNCT3_SLT) ? `ALU_CODE_SLT :
						 (FUNCT3 == `FUNCT3_SLTU) ? `ALU_CODE_SLTU :
						`ALU_CODE_INVALID;
endmodule

/**
NOTE:
WARNING: the immediate has different opcode + funct3 decoding schemes
*/