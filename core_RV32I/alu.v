`timescale 1ns/10ps
`include "define.vh"

/**
An ALU "normally" doesn't require any 
- Registers
- reset signals
Since it is supposed to be purely combinatorial.
*/

module alu (
    input [9:0] ALU_CID,
    input [31:0] ALU_I1,
    input [31:0] ALU_I2,
    output [31:0] ALU_O
);


// ARITHMETIC RIGHT SHIFT
wire [63:0] SRA_tmp;
wire [63:0] SRA_tmp_shifted_64;
wire [31:0] SRA_tmp_shifted_32;
assign SRA_tmp = {{32{ALU_I1[31]}}, ALU_I1};
assign SRA_tmp_shifted_64 = {SRA_tmp >> ALU_I2};
assign SRA_tmp_shifted_32 = SRA_tmp_shifted_64[31:0];
// Take the relevant instruction, perform a switch-case
assign ALU_O = (ALU_CID == `CODE_SUM) ? (ALU_I1 + ALU_I2) :
                (ALU_CID == `CODE_SUB) ? (ALU_I1 - ALU_I2) :
                (ALU_CID == `CODE_XOR) ? (ALU_I1 ^ ALU_I2) :
                (ALU_CID == `CODE_OR) ? (ALU_I1 | ALU_I2) :
                (ALU_CID == `CODE_AND) ? (ALU_I1 & ALU_I2) :
                (ALU_CID == `CODE_SLL) ? (ALU_I1 << ALU_I2) :
                (ALU_CID == `CODE_SRL) ? (ALU_I1 >> ALU_I2) :
                (ALU_CID == `CODE_SRA) ? (SRA_tmp_shifted_32):
                (ALU_CID == `CODE_SLT) ? {{31{1'b0}}, {($signed(ALU_I1) < $signed(ALU_I2))}} :
                (ALU_CID == `CODE_SLTU) ? {{31{1'b0}}, {($unsigned(ALU_I1) < $unsigned(ALU_I2))}} :
                32'hff_ff_ff_ff;
endmodule
