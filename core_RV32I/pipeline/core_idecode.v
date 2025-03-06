`timescale 1ns/10ps

`include "define.vh"

module core_idecode #()
(
	input 					CLK, NRST,
	input [31:0] 			INSTRUCTION,
	input 					C_DECODE,
	output reg [6:0] 		OPCODE,
	output reg [2:0] 		FUNCT3,
	output reg [6:0] 		FUNCT7,
	output reg				IS_IMM,
	output reg [31:0]		IMM_DEC,
	// REGISTER READ / WRITES
	output reg [4:0] 		REG_ARADDR1,
	output reg [4:0] 		REG_ARADDR2,
	output reg [4:0] 		REG_AWADDR
);
	// ********************* IMMEDIATE DECODING **********************
	wire [11:0] imm_I_instr, imm_S_instr;
	wire [11:0] imm_B_instr;
	wire [31:0] imm_U_instr_ls;
	wire [19:0] imm_J_instr;

	assign imm_I_instr = INSTRUCTION[31:20]; // 12 bits
	assign imm_S_instr = {INSTRUCTION[31:25], INSTRUCTION[11:7]}; // 12 bits
	assign imm_B_instr = {INSTRUCTION[31], INSTRUCTION[7], INSTRUCTION[30:25], INSTRUCTION[11:8]}; // 12 bits
	assign imm_J_instr = {INSTRUCTION[31], INSTRUCTION[19:12], INSTRUCTION[20], INSTRUCTION[30:21]}; // 20 bits

	// Immediate I extended
	wire [31:0] imm_I_extended, imm_S_extended, imm_B_extended, imm_J_extended, imm_U_extended;
	assign imm_U_extended = {INSTRUCTION[31:12], 12'b0};
	// NOTE: the I-immediate and funct7 are different in case of an slli, srli, srai, slti
	assign imm_I_extended = {{20{imm_I_instr[11]}}, imm_I_instr};
	assign imm_S_extended = {{20{imm_S_instr[11]}}, imm_S_instr};
	assign imm_B_extended = {{20{imm_B_instr[11]}}, imm_B_instr} << 1;
	assign imm_J_extended = {{12{imm_J_instr[19]}}, imm_J_instr} << 1;
	
	// SIGNALS
	wire [31:0] imm;
	wire is_imm;
	wire [2:0] funct3;
	wire [6:0] funct7;
	wire [4:0] reg_araddr1;
	wire [4:0] reg_araddr2;
	wire [4:0] reg_awaddr;
	wire [6:0] opcode;

	assign opcode = INSTRUCTION[6:0];

	assign imm = (`OPCODE_I_ALU == opcode) ? imm_I_extended :
				 (`OPCODE_S == opcode) ? imm_S_extended :
				 (`OPCODE_B == opcode) ? imm_B_extended :
				 ((`OPCODE_U_LUI == opcode) || (`OPCODE_U_AUIPC == opcode)) ? imm_U_extended :
				 (`OPCODE_J_JAL == opcode) ? imm_J_extended :
				 32'hDEADBEEF;
	

	assign is_imm = (`OPCODE_I_ALU == opcode) || (`OPCODE_S == opcode)
	|| (`OPCODE_B == opcode) || (`OPCODE_U_LUI == opcode)
	|| (`OPCODE_U_AUIPC == opcode) || (`OPCODE_J_JAL == opcode);

	// FUNCT3/7
	assign funct3 = INSTRUCTION[14:12];
	assign funct7 = INSTRUCTION[31:25];

	// READ / WRITE ADDRESS
	assign reg_awaddr = INSTRUCTION[11:7];
	assign reg_araddr1 = INSTRUCTION[19:15];
	assign reg_araddr2 = INSTRUCTION[24:20];

	always @(posedge CLK)
	begin
		if (!NRST)
		begin
			IMM_DEC <= 32'hDEADBEEF;
			IS_IMM <= 0;
			REG_ARADDR1 <= 0;
			REG_ARADDR2 <= 0;
			REG_AWADDR <= 0;
		end
		else if (C_DECODE)
		begin
			// IMMEDIATE
			IS_IMM <= is_imm;
			IMM_DEC <= imm;
			// OPCODE
			OPCODE <= opcode;
			// FUNCT3/7
			FUNCT3 <= funct3;
			FUNCT7 <= funct7;
			// READ / WRITE REGISTER
			REG_AWADDR <= reg_awaddr;
			REG_ARADDR1 <= reg_araddr1;
			REG_ARADDR2 <= reg_araddr2;
		end
		else;
	end
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