`timescale 1ns/10ps


// FOR NOW: no clock / reset needed since this "should" be purely combinatorial
module control (
    // * ALU COMMANDS
    output alu_cid_out,
    output [31:0] alu_arg1_out,
    output [31:0] alu_arg2_out,
    input [31:0] alu_arg_in,

    // * REGISTER READ / WRITE
    input wr_en,
    output [4:0] wr_idx_out,
    output [4:0] rd_idx1_out,
    output [4:0] rd_idx2_out,
    output [31:0] wr_data_out,
    // Should be read by the control unit and redirected depending on the instruction
    input [31:0] rd_data1_in,
    input [31:0] rd_data2_in,

    // * PROGRAM COUNTER
    input [31:0] pc,
    output [31:0] pc_next,

    // * DATA MEMORY
    input [31:0] dmem_in,
    output dmem_addr_out,

    // * INSTRUCTION MEMORY
    input [31:0] imem_in
);

/*
SORT INTO INSTRUCTION TYPES
- ALU required?
- data memory access (Load / Store) required?
- Immediate extraction logic required?
- Operation on program counter required?
*/
wire imm_instr, alu_instr, pc_instr;
assign imem_opcode = imem_in[6:0];

// This stuff should be replaced by a switch-case statement in sysverilog to make it more readable
// alu-related instruction
assign alu_instr = (OPCODE_I_ALU == imem_opcode)
                    || (OPCODE_R == imem_opcode);
// instruction with immediate
assign imm_instr = (OPCODE_I_ALU == imem_opcode)
                    || (OPCODE_S == imem_opcode)
                    || (OPCODE_B == imem_opcode)
                    || (OPCODE_U == imem_opcode)
                    || (OPCODE_J == imem_opcode);

// Instruction for program counter jump
assign pc_instr = (OPCODE_B == imem_opcode)
                || (OPCODE_J_JAL == imem_opcode)
                || (OPCODE_I_JALR == imem_opcode);

// Instruction with memory access
// assign dmem_instr = (..


/**
DECODE FUNC3 and FUNC7
**/
wire [2:0] funct3;
wire [6:0] funct7;
assign funct3 = imem_in[14:12];
assign funct7 = imem_in[31:25];

/**
DECODE the IMMEDIATES
**/
wire [11:0] imm_I_instr, imm_S_instr;
wire [9:0] imm_B_instr;
wire [19:0] imm_U_instr, imm_J_instr;

assign imm_I_instr = imem_in[31:20]; // 12 bits
assign imm_S_instr = {imem_in[31:25], imem_in[11:7]}; // 12 bits
assign imm_B_instr = {imem_in[30:25], imem_in[11:8]}; // 10 bits
assign imm_U_instr = imem_in[31:12]; // 20 bits
assign imm_J_instr = {imem_in[30:21], imem_in[19:12]}; // 20 bits

// ********************* ALU_DECODING *******************************
// Set the register read indices
// *** ALU CID ***
// Use funct3, funct7 to create the opcode in case of OPCODE_R || OPCODE_I_ALU and it being a left / right shift
wire alu_cid_long;
assign alu_cid_long = {funct3, funct7}; // With funct7 being part of Imm_I
// Use funct3 to create the opcode in case of the immediate instruction not being one of the ALU instructions
wire alu_cid_short;
assign alu_cid_short = {funct3, {7{1'b0}}};

// Decide whether we use the immediate as indication or as an argument
wire alu_cid_out = ( (alu_instr == OPCODE_R) ||
                    ((alu_instr == OPCODE_I_ALU) &&
                    ((funct3 == FUNCT3_SLL) || (funct3 === FUNCT3_SR))) )
                    ? alu_cid_long : alu_cid_short;

// *** REGISTER READ INDICES ***
assign rd_idx1_out = imem_in[15:19];
assign rd_idx2_out = imem_in[20:24];

// *** ALU ARGUMENTS ***
wire [31:0] alu_arg2_imm;
assign alu_arg1_out = rd_data1_in;

// Part of the immediate will be used as sub-code.
assign alu_arg2_imm = (funct3 != FUNCT3_SR) ? (imm_I_instr) : {7{1'b0}, imm_I_instr[4:0]};
// Assign the output argument of the ALU depending on whether there's shifting going on or not
assign alu_arg2_out = (alu_instr == OPCODE_R) ? rd_data2_in : alu_arg2_imm;

// *** ALU OUTPUT STORING ***
wire [4:0] alu_wr_idx_out;
assign alu_wr_idx_out = imem_in[11:7];

//! TODO: Additional "wr_en" should be set eventually with if's and else's

// ***************************** PROGRAM_COUNTER INCREMENT **********************************
/**
DECODE THE PROGRAM COUNTER INCREMENT IN CASE OF PROGRAM COUNTER CHANGE
- Branching
- jump
**/

// *** Possible increment ***
wire [31:0] pc_next_default, pc_next_br, pc_next_jal, pc_next_jalr;

// * default
assign pc_next_default = pc + 4;

// * Branching (conditional jump)
assign pc_next_br = pc + imm_B_instr;

// Make sure to check additional branch condition
assign br_eq = (rd_data1_in == rd_data2_in);
assign br_ne = (!br_eq);

// Numbers in verilog are signed by default
assign br_blt = (rd_data1_in < rd_data2_in);
assign br_bge = (!br_blt);

// Unsigned
assign br_bltu = ($unsigned(rd_data1_in) < $unsigned(rd_data2_in));
assign br_bgeu = (!br_bge);



// * Jump and link (unconditional jump)
assign pc_next_jal = pc + imm_J_instr;
assign pc_next_jalr = pc + imm_I_instr;

// *** Determining actual increment ***
assign pc_next = (imem_opcode)

/**
DECODE THE DATA_MEMORY LOAD INSTRUCTION DETAILS
**/



/**
DECODE THE DATA_MEMORY STORE INSTRUCTION DETAILS
**/




endmodule
