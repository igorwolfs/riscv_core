`timescale 1ns/10ps

`include "define.vh"

module core_idecode #()
(
	input 					CLK, NRST,
	input  [31:0] 			INSTRUCTION,
	output [6:0] 			OPCODE,
	output reg [2:0] 		FUNCT3,
	output reg [6:0] 		FUNCT7,
	output reg				C_ISIMM,
	output reg [31:0]		IMM_DEC,
	output reg				C_ALU,
	output reg				C_BRANCH,
	output reg 				C_DOLOAD,
	output reg 				C_DOSTORE,
	output reg [3:0]		C_WB_CODE,
	output reg				C_REG_AWVALID,
	output reg 				C_CMEM,

	// REGISTER READ / WRITES
	output [4:0] 			REG_ARADDR1,
	output [4:0] 			REG_ARADDR2,
	output [4:0] 			REG_AWADDR
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
	wire [2:0] funct3;
	wire [6:0] funct7;
	wire [4:0] reg_araddr1;
	wire [4:0] reg_araddr2;

	assign OPCODE = INSTRUCTION[6:0];

	always @(*)
	begin
		case (OPCODE)
			`OPCODE_I_ALU, `OPCODE_I_LOAD, `OPCODE_I_JALR:
				IMM_DEC = imm_I_extended;
			`OPCODE_S:
				IMM_DEC = imm_S_extended;
			`OPCODE_B:
				IMM_DEC = imm_B_extended;
			`OPCODE_U_LUI, `OPCODE_U_AUIPC:
				IMM_DEC = imm_U_extended;
			`OPCODE_J_JAL:
				IMM_DEC = imm_J_extended;
			default: IMM_DEC = 32'hDEADBEEF;
		endcase
	end
	
	// FUNCT3/7
	assign funct3 = INSTRUCTION[14:12];
	assign funct7 = INSTRUCTION[31:25];

	// READ / WRITE ADDRESS
	assign REG_AWADDR = INSTRUCTION[11:7];
	assign REG_ARADDR1 = INSTRUCTION[19:15];
	assign REG_ARADDR2 = INSTRUCTION[24:20];

// ASSIGN NEXT STATE DEPENDING ON WHETHER S_IFETCH WAS SUCCESFULL
always @(*) begin
	C_ISIMM = 1'b0;
	C_ALU = 1'b0;
	C_REG_AWVALID = 1'b0;
	C_CMEM = 1'b0;
	C_DOSTORE = 1'b0;
	C_DOLOAD = 1'b0;
	C_BRANCH = 1'b0;
	C_WB_CODE = `WB_CODE_NONE;
	case (OPCODE)
	`OPCODE_R: begin
		C_ALU = 1'b1;
		C_WB_CODE = `WB_CODE_ALU;
		C_REG_AWVALID = 1'b1;
	end
	`OPCODE_I_ALU: begin
		C_ALU = 1'b1;
		C_WB_CODE = `WB_CODE_ALU;
		C_REG_AWVALID = 1'b1;
		C_ISIMM = 1'b1;
	end
	`OPCODE_I_LOAD: begin
		C_CMEM = 1'b1;
		C_DOLOAD = 1'b1;
		C_WB_CODE = `WB_CODE_LOAD;
		C_REG_AWVALID = 1'b1;
		C_ISIMM = 1'b1;
	end
	`OPCODE_S: begin
		C_CMEM = 1'b1;
		C_DOSTORE = 1'b1;
		C_WB_CODE = `WB_CODE_STORE;
		C_ISIMM = 1'b1;
	end
	`OPCODE_B: begin
		C_BRANCH = 1'b1;
		C_WB_CODE = `WB_CODE_BRANCH; // IF WB_CODE_BRANCH AND c_branch THEN take branch
		C_ISIMM = 1'b1;
	end
	`OPCODE_J_JAL: begin
		C_WB_CODE = `WB_CODE_JAL;
		C_REG_AWVALID = 1'b1;
		C_ISIMM = 1'b1;
	end
	`OPCODE_I_JALR: begin
		C_WB_CODE = `WB_CODE_JALR;
		C_REG_AWVALID = 1'b1;
		C_ISIMM = 1'b1;
		// FLAG TO INDICATE RS1+IMM -> PC instead of IMM += PC
	end
	`OPCODE_U_LUI: begin
		C_WB_CODE = `WB_CODE_LUI;
		C_REG_AWVALID = 1'b1;
		C_ISIMM = 1'b1;
		// Make sure the imm is written here
	end
	`OPCODE_U_AUIPC: begin
		C_WB_CODE = `WB_CODE_AUIPC;
		C_REG_AWVALID = 1'b1;
		C_ISIMM = 1'b1;
		// Make sure the imm + PC is written here
	end
	default: ;
	endcase
end

	always @(posedge CLK)
	begin
		// FUNCT3/7
		FUNCT3 <= funct3;
		FUNCT7 <= funct7;
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