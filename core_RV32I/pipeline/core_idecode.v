`timescale 1ns/10ps

`include "define.vh"

module core_idecode #()
(
	input [31:0] 		INSTRUCTION,
	output [6:0] 		OPCODE,
	output [2:0] 		FUNCT3,
	output [6:0] 		FUNCT7,
	output [31:0]		IMM,
	// REGISTER READ / WRITES
	output [4:0] 		REG_ARADDR1,
	output [4:0] 		REG_ARADDR2,
	output [4:0] 		REG_AWADDR
);
	assign OPCODE = INSTRUCTION[6:0];

	// ********************* IMMEDIATE DECODING **********************
	wire [11:0] imm_I_instr, imm_S_instr;
	wire [11:0] imm_B_instr;
	wire [31:0] imm_U_instr_ls;
	wire [19:0] imm_J_instr;

	assign imm_I_instr = IMEM_RDATA[31:20]; // 12 bits
	assign imm_S_instr = {IMEM_RDATA[31:25], IMEM_RDATA[11:7]}; // 12 bits
	assign imm_B_instr = {IMEM_RDATA[31], IMEM_RDATA[7], IMEM_RDATA[30:25], IMEM_RDATA[11:8]}; // 12 bits
	assign imm_J_instr = {IMEM_RDATA[31], IMEM_RDATA[19:12], IMEM_RDATA[20], IMEM_RDATA[30:21]}; // 20 bits

	// Immediate I extended
	wire [31:0] imm_I_extended, imm_S_extended, imm_B_extended, imm_J_extended, imm_U_extended;
	assign imm_U_extended = {IMEM_RDATA[31:12], 12'b0};
	// NOTE: the I-immediate and funct7 are different in case of an slli, srli, srai, slti
	assign imm_I_extended = {{20{imm_I_instr[11]}}, imm_I_instr};
	assign imm_S_extended = {{20{imm_S_instr[11]}}, imm_S_instr};
	assign imm_B_extended = {{20{imm_B_instr[11]}}, imm_B_instr} << 1;
	assign imm_J_extended = {{12{imm_J_instr[19]}}, imm_J_instr} << 1;

	assign IMM = ((`OPCODE_I_ALU == OPCODE) ? imm_I_extended :
				 (`OPCODE_S == OPCODE) ? imm_S_extended :
				(`OPCODE_B == OPCODE) ? imm_B_extended :
				((`OPCODE_U_LUI == OPCODE) || (`OPCODE_U_AUIPC == OPCODE)) ? imm_U_extended :
				(`OPCODE_J_JAL == OPCODE)) ? imm_J_extended :
				32'hDEADBEEF;

	// FUNCT3/7
	assign FUNCT3 = INSTRUCTION[14:12];
	assign FUNCT7 = INSTRUCTION[31:25];

	// READ / WRITE ADDRESS
	assign REG_AWADDR = INSTRUCTION[11:7];
	assign REG_ARADDR1 = INSTRUCTION[19:15];
	assign REG_ARADDR2 = INSTRUCTION[24:20];
endmodule

/**
ARGUMENTS:
- gets opcode
- gets funct3, funct7, rd, rs1, rs2
- 
DOES:
- generates the immediate depending on the INSTRUCTION
- decode the instruction
*/