`timescale 1ns/10ps


// FOR NOW: no clock / reset needed since this "should" be purely combinatorial
module control (
    // ALU COMMANDS
    output alu_cid_out,
    output alu_arg1_out,
    output alu_arg2_out,
    input alu_arg_in,

    // REGISTER READ / WRITE
    input wr_en,
    input [4:0] wr_idx_in,
    input [4:0] rd_idx1_in,
    input [4:0] rd_idx2_in,
    input [31:0] wr_data_in,
    output [31:0] rd_data_1_out,
    output [31:0] rd_data_2_out,

    // PROGRAM COUNTER
    input [31:0] pc,
    output [31:0] pc_next,

    // DATA MEMORY
    input [31:0] dmem_in,
    output dmem_addr_out,

    // INSTRUCTION MEMORY
    input [31:0] imem_in

);

// ALU COMMANDS





endmodule
