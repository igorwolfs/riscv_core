//! **** RUNTIME SETTINGS
`define SIMULATION

//! **** INSTRUCTIONS ****
// 2-argument arithmetic instructions
`define OPCODE_R 7'b0110011

// IMMEDIATE Arithmetic INSTRUCTION
`define OPCODE_I_ALU 7'b0010011

// LOAD INSTRUCTIONS
`define OPCODE_I_LOAD 7'b0000011

// STORE INSTRUCTIONS
`define OPCODE_S 7'b0100011

// CONDITIONAL JUMP / BRANCH INSTRUCTIONS
`define OPCODE_B 7'b1100011

// UNCONDITIONAL JUMP INSTRUCTIONS
`define OPCODE_J_JAL 7'b1101111
`define OPCODE_I_JALR 7'b1100111

// PROGRAM COUNTER LOAD ISNTRUCTIONS
`define OPCODE_U_LUI 7'b0110111
`define OPCODE_U_AUIPC 7'b0010111

// EBREAK AND ECALL INSTRUCTIONS
`define OPCODE_SYS 7'b1110011

//! **** SUB-INSTRUCTIONS ****
// **** ARITHMETIC SUB-INSTRUCTIONS ****
// * FUNCT3
// ADD vs SUB -> funct7
`define FUNCT3_ADD 3'h0
`define FUNCT3_XOR 3'h4
`define FUNCT3_OR 3'h6
`define FUNCT3_AND 3'h7
`define FUNCT3_SLL 3'h1
`define FUNCT3_SR 3'h5
// Arithmetic vs logical -> funct7
`define FUNCT3_SLT 3'h2
`define FUNCT3_SLTU 3'h3

// FUNCT7 (DUAL ARGUMENT)
// Subtract
`define FUNCT7_SUB 7'h20
// Shift right arithmetic (0 -> logical shift)
`define FUNCT7_SRA 7'h20

// FUNCT7 (IMMEDIATE)
// value h(5:11) = 0x0 of the immediate
`define FUNCT7_SLLI_IMM_MASK 12'b0
// value h(5:11) = 0x0 of the immediate
`define FUNCT7_SRLI_IMM_MASK 12'b0
// value h(5:11) = 0x20 of the immediate
`define FUNCT7_SRAI_IMM_MASK 12'b1000_0000_0000

// **** LOAD BYTE SUB-INSTRUCTIONS ****
// FUNCT3
`define FUNCT3_LB 3'h0
`define FUNCT3_LH 3'h1
`define FUNCT3_LW 3'h2
`define FUNCT3_LBU 3'h4
`define FUNCT3_LHU 3'h5

// **** STORE BYTE SUB-INSTRUCTIONS ****
`define FUNCT3_SB 3'h0
`define FUNCT3_SH 3'h1
`define FUNCT3_SW 3'h2

// **** BRANCH SUB-INSTRUCTIONS ****
`define FUNCT3_BEQ 3'h0
`define FUNCT3_BNE 3'h1
`define FUNCT3_BLT 3'h4
`define FUNCT3_BGE 3'h5
`define FUNCT3_BLTU 3'h6
`define FUNCT3_BGEU 3'h7


// ! **** ALU INSTRUCTIONS ****
`define ALU_CODE_ADD	0
`define ALU_CODE_SUB	1
`define ALU_CODE_XOR	2
`define ALU_CODE_OR 	3
`define ALU_CODE_AND	4
`define ALU_CODE_SLL	5
`define ALU_CODE_SRL	6
`define ALU_CODE_SRA	7
`define ALU_CODE_SLT	8
`define ALU_CODE_SLTU	9
`define ALU_CODE_INVALID	4'b1111

//! **** WB CODES *****
`define WB_CODE_NONE 		0
`define WB_CODE_LOAD		1
`define WB_CODE_STORE		2
`define WB_CODE_BRANCH		3
`define WB_CODE_JAL			4
`define WB_CODE_JALR		5
`define WB_CODE_LUI			6
`define WB_CODE_AUIPC		7
`define WB_CODE_ALU			8
/**
For PC and regwrite purposes
- WRITE TO REGISTER: Switch-case in top_cpu that
	- Doesn't write on BRANCH_OK (controlled by single clocked signal)
	- Writes the relevant way on all other cases
- PC INCREMENT: switch-case in top_cpu that
	- Doesn't increment PC on branch fail
	- In all other cases manages the increments with an always @(*)
*/