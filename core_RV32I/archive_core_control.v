`timescale 1ns/10ps
`include "define.vh"

// FOR NOW: no clock / reset needed since this "should" be purely combinatorial
module core_control (
    // * ALU COMMANDS
    output [9:0] ALU_CID,
    output [31:0] ALU_I1,
    output [31:0] ALU_I2,
    input [31:0] ALU_O,

    // * REGISTER READ / WRITE
    output REG_AWVALID,
    output [4:0] REG_AWADDR,
    output [4:0] REG_ARADDR1,
    output [4:0] REG_ARADDR2,
    output [31:0] REG_WDATA,

    // Should be read by the control unit and redirected depending on the instruction
    input [31:0] REG_RDATA1,
    input [31:0] REG_RDATA2,

    // * PROGRAM COUNTER
    input [31:0] PC,
    output [31:0] PC_N,

    // * DATA MEMORY
    input [31:0] DMEM_RDATA,
    output [31:0] DMEM_ARADDR,
    output DMEM_AWVALID,
    output [31:0] DMEM_WDATA,
    output [31:0] DMEM_AWADDR,

    // * INSTRUCTION MEMORY
    input [31:0] IMEM_RDATA
);

// **************************** INSTRUCTION TYPE *********************
wire imm_instr, alu_instr, pc_instr;
wire [6:0] imem_opcode;
assign imem_opcode = IMEM_RDATA[6:0];

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
assign REG_AWVALID = alu_instr || (imem_opcode == `OPCODE_J_JAL) || (imem_opcode == `OPCODE_I_JALR)
    || (imem_opcode == `OPCODE_I_LOAD) || (imem_opcode == `OPCODE_U_LUI)
    || (imem_opcode == `OPCODE_U_AUIPC);

// Instruction for memory write
assign DMEM_AWVALID = (imem_opcode == `OPCODE_S);

// Instruction for wire

// ********************* IMMEDIATE DECODING **********************
wire [11:0] imm_I_instr, imm_S_instr;
wire [11:0] imm_B_instr;
wire [31:0] imm_U_instr_ls;
wire [19:0] imm_J_instr;

assign imm_I_instr = IMEM_RDATA[31:20]; // 12 bits
assign imm_S_instr = {IMEM_RDATA[31:25], IMEM_RDATA[11:7]}; // 12 bits
assign imm_B_instr = {IMEM_RDATA[31], IMEM_RDATA[7], IMEM_RDATA[30:25], IMEM_RDATA[11:8]}; // 12 bits
assign imm_U_instr_ls = {IMEM_RDATA[31:12], 12'b0}; // 20 bits
assign imm_J_instr = {IMEM_RDATA[31], IMEM_RDATA[19:12], IMEM_RDATA[20], IMEM_RDATA[30:21]}; // 20 bits


// Immediate I extended
wire [31:0] imm_I_extended, imm_S_extended, imm_B_extended, imm_J_extended;
assign imm_I_extended = {{20{imm_I_instr[11]}}, imm_I_instr};
assign imm_S_extended = {{20{imm_S_instr[11]}}, imm_S_instr};
assign imm_B_extended = {{20{imm_B_instr[11]}}, imm_B_instr} << 1;
assign imm_J_extended = {{12{imm_J_instr[19]}}, imm_J_instr} << 1;

// ******************* DEFAULT DECODING (READ/WRITE, FUNCT3, FUNCT7) **********************

wire [2:0] funct3;
wire [6:0] funct7;
assign funct3 = IMEM_RDATA[14:12];
assign funct7 = IMEM_RDATA[31:25];

assign REG_AWADDR = IMEM_RDATA[11:7];
assign REG_ARADDR1 = IMEM_RDATA[19:15];
assign REG_ARADDR2 = IMEM_RDATA[24:20];

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
assign ALU_CID = ( (imem_opcode == `OPCODE_R) ||
                    ((imem_opcode == `OPCODE_I_ALU) &&
                    ((funct3 == `FUNCT3_SLL) || (funct3 == `FUNCT3_SR))) )
                    ? alu_cid_long : alu_cid_short;

// *** ALU ARGUMENTS ***
wire [31:0] alu_arg2_imm;
assign ALU_I1 = REG_RDATA1;

// Part of the immediate will be used as sub-code.
assign alu_arg2_imm = (funct3 != `FUNCT3_SR) ? imm_I_extended : ({27'b0, imm_I_instr[4:0]});

// In case of an SRL, SRA or SLL only the first 5 bits are used for the shift
wire alu_shift_op;
assign alu_shift_op = ((ALU_CID == `CODE_SRL) || (ALU_CID == `CODE_SLL) || (ALU_CID == `CODE_SRA));

// Assign the output argument of the ALU depending on whether there's shifting going on or not
assign ALU_I2 = (imem_opcode == `OPCODE_R) && (!alu_shift_op) ? REG_RDATA2 :
                        (imem_opcode == `OPCODE_R) && (alu_shift_op) ? {27'b0, REG_RDATA2[4:0]} : 
                        alu_arg2_imm;

// *** ALU OUTPUT STORING ***
wire [31:0] reg_data_out_alu;
assign reg_data_out_alu = ALU_O; // Write alu value in register

// ***************************** PROGRAM_COUNTER INCREMENT **********************************
/**
DECODE THE PROGRAM COUNTER INCREMENT IN CASE OF PROGRAM COUNTER CHANGE
- Branching
- jump
**/
// *** Possible increment ***
wire [31:0] pc_next_default, pc_next_br, pc_next_jal, pc_next_jalr;

// * default
assign pc_next_default = PC + 4;

// * Branching (conditional jump)
assign pc_next_br = PC + imm_B_extended;

// * Jump (unconditional jump)
// JAL
assign pc_next_jal = PC + imm_J_extended;

// JALR (NOTE: rd_idx1, wr_idx already set)
assign pc_next_jalr = REG_RDATA1 + imm_I_extended;

// register write for jump instruction
wire [31:0] reg_data_out_jump;
assign reg_data_out_jump = PC + 4;

// *** Determining actual increment ***
assign PC_N = ((imem_opcode == `OPCODE_B) && br_cond) ? pc_next_br :
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
// - (if it's a load instruction -> read from dmem_rd_addr
// - (if it's a store instruction -> make sure to read from dmem_wr_addr so you can mask)
assign DMEM_ARADDR = (imem_opcode == `OPCODE_I_LOAD) ? (REG_RDATA1 + imm_I_extended) :
                        (DMEM_AWADDR);

// Load format
// Get first 2 bits

// If 2 byte offset is 0, 1, 2, 3 -> change relevant byte loaded

assign load_b = (DMEM_ARADDR[1:0] == 2'b00) ? DMEM_RDATA[7:0] :
                (DMEM_ARADDR[1:0] == 2'b01) ? DMEM_RDATA[15:8] :
                (DMEM_ARADDR[1:0] == 2'b10) ? DMEM_RDATA[23:16] :
                DMEM_RDATA[31:24];

assign load_hw = (DMEM_ARADDR[1:0] == 2'b00) ? DMEM_RDATA[15:0] :
                DMEM_RDATA[31:16];

assign load_w = DMEM_RDATA[31:0];
/*
assign load_bu = (DMEM_ARADDR[1:0] == 2'b00) ? $unsigned(DMEM_RDATA[7:0]) :
                (DMEM_ARADDR[1:0] == 2'b01) ? $unsigned(DMEM_RDATA[15:8]) :
                (DMEM_ARADDR[1:0] == 2'b10) ? $unsigned(DMEM_RDATA[23:16]) :
                $unsigned(DMEM_RDATA[31:24]);

assign load_hwu = (DMEM_ARADDR[1:0] == 2'b00) ? $unsigned(DMEM_RDATA[15:0]) :
                $unsigned(DMEM_RDATA[31:16]);
*/
wire [31:0] reg_data_out_load;
assign reg_data_out_load = (funct3 == `FUNCT3_LB) ? {{24{load_b[7]}}, load_b} :
                        (funct3 == `FUNCT3_LH) ? {{16{load_hw[15]}}, load_hw} :
                        (funct3 == `FUNCT3_LW) ? load_w :
                        (funct3 == `FUNCT3_LBU) ? {24'b0, load_b} :
                        {16'b0, load_hw};

// *** LUI / AUIPC instruction
wire [31:0] reg_data_out_lui,  reg_data_out_auipc;
// LUI
assign reg_data_out_lui = imm_U_instr_ls;

// AUIPC
assign reg_data_out_auipc = imm_U_instr_ls + PC;

// *** Decide on which data to write
assign REG_WDATA = alu_instr ? reg_data_out_alu :
                    ((imem_opcode == `OPCODE_J_JAL) || (imem_opcode == `OPCODE_I_JALR)) ? reg_data_out_jump:
                    (imem_opcode == `OPCODE_I_LOAD) ? reg_data_out_load :
                    (imem_opcode == `OPCODE_U_LUI) ? reg_data_out_lui :
                    reg_data_out_auipc;

// ************************************ DMEM WRITE *************************************
// Store instructions
wire [31:0] store_b, store_hw, store_w;

assign store_b = (DMEM_AWADDR[1:0] == 2'b00) ? {DMEM_RDATA[31:8], REG_RDATA2[7:0]} :
                (DMEM_AWADDR[1:0] == 2'b01) ? {DMEM_RDATA[31:16], REG_RDATA2[7:0], DMEM_RDATA[7:0]} :
                (DMEM_AWADDR[1:0] == 2'b10) ? {DMEM_RDATA[31:24], REG_RDATA2[7:0], DMEM_RDATA[15:0]} :
                {REG_RDATA2[7:0], DMEM_RDATA[23:0]};

assign store_hw = (DMEM_AWADDR[1:0] == 2'b00) ? {DMEM_RDATA[31:16], REG_RDATA2[15:0]} :
                    (DMEM_AWADDR[1:0] == 2'b01) ? {DMEM_RDATA[31:24], REG_RDATA2[15:0], DMEM_RDATA[7:0]} :
                    {REG_RDATA2[15:0], DMEM_RDATA[15:0]};

assign store_w = (REG_RDATA2[31:0]);

assign DMEM_AWADDR = REG_RDATA1 + imm_S_extended;
assign DMEM_WDATA = (funct3 == `FUNCT3_SB) ? store_b :
                        (funct3 == `FUNCT3_SH) ? store_hw :
                        store_w;

endmodule
