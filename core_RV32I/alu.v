`timescale 1ns/10ps
`include "define.vh"

/**
An ALU "normally" doesn't require any 
- Registers
- reset signals
Since it is supposed to be purely combinatorial.
*/

module alu (
    input [9:0] alu_cid_in,
    input [31:0] alu_arg1_in,
    input [31:0] alu_arg2_in,
    output [31:0] alu_arg_out
);

// funct3, funct7 is the code
localparam [9:0] CODE_SUM = {`FUNCT3_ADD, 7'b0};
localparam [9:0] CODE_SUB = {`FUNCT3_ADD, `FUNCT7_SUB};
localparam [9:0] CODE_XOR = {`FUNCT3_XOR, 7'b0};
localparam [9:0] CODE_OR = {`FUNCT3_OR, 7'b0};
localparam [9:0] CODE_AND = {`FUNCT3_AND, 7'b0};
localparam [9:0] CODE_SLL = {`FUNCT3_SLL, 7'b0};
localparam [9:0] CODE_SRL = {`FUNCT3_SR, 7'b0};
localparam [9:0] CODE_SRA = {`FUNCT3_SR, `FUNCT7_SRA};
localparam [9:0] CODE_SLT = {`FUNCT3_SLT, 7'b0};
localparam [9:0] CODE_SLTU = {`FUNCT3_SLTU, 7'b0};


// ARITHMETIC RIGHT SHIFT
wire [63:0] SRA_tmp;
wire [63:0] SRA_tmp_shifted_64;
wire [31:0] SRA_tmp_shifted_32;
assign SRA_tmp = {{32{alu_arg1_in[31]}}, alu_arg1_in};
assign SRA_tmp_shifted_64 = {SRA_tmp >> alu_arg2_in};
assign SRA_tmp_shifted_32 = SRA_tmp_shifted_64[31:0];
// Take the relevant instruction, perform a switch-case
assign alu_arg_out = (alu_cid_in == CODE_SUM) ? (alu_arg1_in + alu_arg2_in) :
                (alu_cid_in == CODE_SUB) ? (alu_arg1_in - alu_arg2_in) :
                (alu_cid_in == CODE_XOR) ? (alu_arg1_in ^ alu_arg2_in) :
                (alu_cid_in == CODE_OR) ? (alu_arg1_in | alu_arg2_in) :
                (alu_cid_in == CODE_AND) ? (alu_arg1_in & alu_arg2_in) :
                (alu_cid_in == CODE_SLL) ? (alu_arg1_in << alu_arg2_in) :
                (alu_cid_in == CODE_SRL) ? (alu_arg1_in >> alu_arg2_in) :
                (alu_cid_in == CODE_SRA) ? (SRA_tmp_shifted_32):
                (alu_cid_in == CODE_SLT) ? {{31{1'b0}}, {($signed(alu_arg1_in) < $signed(alu_arg2_in))}} :
                (alu_cid_in == CODE_SLTU) ? {{31{1'b0}}, {($unsigned(alu_arg1_in) < $unsigned(alu_arg2_in))}} :
                32'hff_ff_ff_ff;


endmodule
