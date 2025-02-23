`timescale 1ns/10ps
`include "define.vh"

// FOR NOW: no clock / reset needed since this "should" be purely combinatorial
module control (
    // * ALU COMMANDS
    output [9:0] alu_cid_out,
    output [31:0] alu_arg1_out,
    output [31:0] alu_arg2_out,
    input [31:0] alu_arg_in,

    // * REGISTER READ / WRITE
    output reg_wr_en_out,
    output [4:0] reg_wr_idx_out,
    output [4:0] reg_rd_idx1_out,
    output [4:0] reg_rd_idx2_out,
    output [31:0] reg_wr_data_out,
    // Should be read by the control unit and redirected depending on the instruction
    input [31:0] reg_rd_data1_in,
    input [31:0] reg_rd_data2_in,

    // * PROGRAM COUNTER
    input [31:0] pc,
    output [31:0] pc_next,

    // * DATA MEMORY
    input [31:0] dmem_rd_data_in,
    output [31:0] dmem_rd_addr_out,
    output dmem_wr_en_out,
    output [31:0] dmem_wr_data_out,
    output [31:0] dmem_wr_addr_out,

    // * INSTRUCTION MEMORY
    input [31:0] imem_in
);


// **************************** INSTRUCTION TYPE *********************
wire imm_instr, alu_instr, pc_instr;
wire [6:0] imem_opcode;
assign imem_opcode = imem_in[6:0];

// This stuff should be replaced by a switch-case statement in sysverilog to make it more readable
// alu-related instruction
assign alu_instr = ((`OPCODE_I_ALU == imem_opcode) || (`OPCODE_R == imem_opcode));
// instruction with immediate
assign imm_instr = ((`OPCODE_I_ALU == imem_opcode)
                    || (`OPCODE_S == imem_opcode)
                    || (`OPCODE_B == imem_opcode)
                    || (`OPCODE_U_LUI == imem_opcode)
                    || (`OPCODE_U_AUIPC == imem_opcode)
                    || (`OPCODE_J_JAL == imem_opcode));

// Instruction for program counter jump
assign pc_instr = (`OPCODE_B == imem_opcode)
                || (`OPCODE_J_JAL == imem_opcode)
                || (`OPCODE_I_JALR == imem_opcode);

// Instruction for register write
assign reg_wr_en_out = alu_instr || (imem_opcode == `OPCODE_J_JAL) || (imem_opcode == `OPCODE_I_JALR)
    || (imem_opcode == `OPCODE_I_LOAD) || (imem_opcode == `OPCODE_U_LUI)
    || (imem_opcode == `OPCODE_U_AUIPC);

// Instruction for memory write
assign dmem_wr_en_out = (imem_opcode == `OPCODE_S);

// Instruction for wire

// ********************* IMMEDIATE DECODING **********************
wire [11:0] imm_I_instr, imm_S_instr;
wire [9:0] imm_B_instr;
wire [31:0] imm_U_instr_ls;
wire [17:0] imm_J_instr;

assign imm_I_instr = imem_in[31:20]; // 12 bits
assign imm_S_instr = {imem_in[31:25], imem_in[11:7]}; // 12 bits
assign imm_B_instr = {imem_in[30:25], imem_in[11:8]}; // 10 bits
assign imm_U_instr_ls = {imem_in[31:12], 12'b0}; // 20 bits
assign imm_J_instr = {imem_in[30:21], imem_in[19:12]}; // 18 bits


// Immediate I extended
wire [31:0] imm_I_extended, imm_S_extended, imm_B_extended, imm_J_extended;
assign imm_I_extended = {{20{imm_I_instr[10]}}, imm_I_instr};
assign imm_S_extended = {{20{imm_S_instr[11]}}, imm_S_instr};
assign imm_B_extended = {{22{imm_B_instr[9]}}, imm_B_instr};
assign imm_J_extended = {{14{imm_J_instr[17]}}, imm_J_instr};

// ******************* DEFAULT DECODING (READ/WRITE, FUNCT3, FUNCT7) **********************

wire [2:0] funct3;
wire [6:0] funct7;
assign funct3 = imem_in[14:12];
assign funct7 = imem_in[31:25];

assign reg_wr_idx_out = imem_in[11:7];
assign reg_rd_idx1_out = imem_in[19:15];
assign reg_rd_idx2_out = imem_in[24:20];

// ********************* ALU_DECODING *******************************
// Set the register read indices
// *** ALU CID ***
// Use funct3, funct7 to create the opcode in case of `OPCODE_R || `OPCODE_I_ALU and it being a left / right shift
wire [9:0] alu_cid_long;
assign alu_cid_long = {funct3, funct7}; // With funct7 being part of Imm_I
// Use funct3 to create the opcode in case of the immediate instruction not being one of the ALU instructions
wire [9:0] alu_cid_short;
assign alu_cid_short = {funct3, {7{1'b0}}};

// Decide whether we use the immediate as indication or as an argument
assign alu_cid_out = ( (imem_opcode == `OPCODE_R) ||
                    ((imem_opcode == `OPCODE_I_ALU) &&
                    ((funct3 == `FUNCT3_SLL) || (funct3 == `FUNCT3_SR))) )
                    ? alu_cid_long : alu_cid_short;

// *** ALU ARGUMENTS ***
wire [31:0] alu_arg2_imm;
assign alu_arg1_out = reg_rd_data1_in;

// Part of the immediate will be used as sub-code.
assign alu_arg2_imm = (funct3 != `FUNCT3_SR) ? imm_I_extended : ({27'b0, imm_I_instr[4:0]});
// Assign the output argument of the ALU depending on whether there's shifting going on or not
assign alu_arg2_out = (imem_opcode == `OPCODE_R) ? reg_rd_data2_in : alu_arg2_imm;

// *** ALU OUTPUT STORING ***
wire [31:0] reg_data_out_alu;
assign reg_data_out_alu = alu_arg_in; // Write alu value in register

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
assign pc_next_br = pc + imm_B_extended;

// * Branching conditions
wire br_eq, br_ne, br_blt, br_bge, br_bltu, br_bgeu, br_cond;

// Make sure to check additional branch condition
assign br_eq = (reg_rd_data1_in == reg_rd_data2_in);
assign br_ne = !br_eq;

// Numbers in verilog are signed by default
assign br_blt = (reg_rd_data1_in < reg_rd_data2_in);
assign br_bge = !br_blt;

// Unsigned
assign br_bltu = ($unsigned(reg_rd_data1_in) < $unsigned(reg_rd_data2_in));
assign br_bgeu = !br_bltu;

// * Check if the branching condition is fulfilled
assign br_cond = ((`FUNCT3_BEQ == funct3) && (br_eq))
                    || ((`FUNCT3_BNE == funct3) && (br_ne))
                    || ((`FUNCT3_BLT == funct3) && (br_blt))
                    || ((`FUNCT3_BGE == funct3) && (br_bge))
                    || ((`FUNCT3_BLTU == funct3) && (br_bltu))
                    || ((`FUNCT3_BGEU == funct3) && (br_bgeu));

// * Jump (unconditional jump)
// JAL
assign pc_next_jal = pc + imm_J_extended;

// JALR (NOTE: rd_idx1, wr_idx already set)
assign pc_next_jalr = reg_rd_data1_in + imm_I_extended;

// register write for jump instruction
wire [31:0] reg_data_out_jump;
assign reg_data_out_jump = pc + 4;

// *** Determining actual increment ***
assign pc_next = ((imem_opcode == `OPCODE_B) && br_cond) ? pc_next_br :
                 (imem_opcode == `OPCODE_J_JAL) ? pc_next_jal :
                 (imem_opcode == `OPCODE_I_JALR) ? pc_next_jalr :
                 pc_next_default;

// ***************************** REGISTER DATA WRITE *****************************
// alu-instructions, Jump instructions, load instructions, lui, aupic
// *** Load instruction ***
// * Determine data-load size
wire [7:0] load_b, load_bu;
wire [15:0] load_hw, load_hwu;
wire [31:0] load_w;

// data read index
assign dmem_rd_addr_out = reg_rd_data1_in + imm_I_extended;

// Load format
assign load_b = dmem_rd_data_in[7:0];
assign load_hw = dmem_rd_data_in[15:0];
assign load_w = dmem_rd_data_in[31:0];
assign load_bu = $unsigned(dmem_rd_data_in[7:0]);
assign load_hwu = $unsigned(dmem_rd_data_in[15:0]);

wire [31:0] reg_data_out_load;
assign reg_data_out_load = (funct3 == `FUNCT3_LB) ? {{24{load_b[7]}}, load_b} :
                        (funct3 == `FUNCT3_LH) ? {{16{load_hw[15]}}, load_hw} :
                        (funct3 == `FUNCT3_LW) ? load_w :
                        (funct3 == `FUNCT3_LBU) ? {24'b0, load_bu} :
                        {16'b0, load_hwu};

// *** LUI / AUIPC instruction
wire [31:0] reg_data_out_lui,  reg_data_out_auipc;
// LUI
assign reg_data_out_lui = imm_U_instr_ls;

// AUIPC
assign reg_data_out_auipc = imm_U_instr_ls + pc;

// *** Decide on which data to write
assign reg_wr_data_out = alu_instr ? reg_data_out_alu :
                    ((imem_opcode == `OPCODE_J_JAL) || (imem_opcode == `OPCODE_I_JALR)) ? reg_data_out_jump:
                    (imem_opcode == `OPCODE_I_LOAD) ? reg_data_out_load :
                    (imem_opcode == `OPCODE_U_LUI) ? reg_data_out_lui :
                    reg_data_out_auipc;

// ************************************ DMEM WRITE *************************************
// Store instructions
wire [7:0] store_b;
wire [15:0] store_hw;
wire [31:0] store_w;

assign store_b = (reg_rd_data2_in[7:0]);
assign store_hw = (reg_rd_data2_in[15:0]);
assign store_w = (reg_rd_data2_in[31:0]);

assign dmem_wr_addr_out = reg_rd_data1_in + imm_S_extended;
assign dmem_wr_data_out = (funct3 == `FUNCT3_SB) ? {{24{store_b[7]}}, store_b} :
                        (funct3 == `FUNCT3_SH) ? {{16{store_hw[15]}}, store_hw} :
                        store_w;

endmodule
