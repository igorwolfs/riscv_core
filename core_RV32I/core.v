`timescale 1ns/10ps

`include "config.vh"
/**


The program counter needs to be updated on every clock cycle.
- PC+4 (normally)
- PC+other_number (depending on )
*/


module core #()
  (
    // SYSTEM
    input  CLK, NRST,

    // External memory interface (when INTERNAL_MEMORY = 0)
    // Data Memory Interface
    output wire [31:0] DMEM_ARADDR,
    input  wire [31:0] DMEM_RDATA,
    output wire [31:0] DMEM_AWADDR,
    output wire [31:0] DMEM_WDATA,
    output wire        DMEM_AWVALID,

    // Instruction Memory Interface
    output wire [31:0] IMEM_ARADDR,
    input  wire [31:0] IMEM_RDATA
  );

  // Internal signals
  wire [31:0] internal_dmem_rdata;
  wire [31:0] internal_imem_rdata;

  // ALU COMMANDS
  wire [31:0] alu_i1, alu_i2, alu_o;
  wire [9:0] alu_cid;

  // REGISTER READ / WRITE
  wire reg_awvalid;
  wire [4:0] reg_wr_idx, reg_rd_idx1, reg_rd_idx2;
  wire [31:0] reg_wr_data, reg_rd_data1, reg_rd_data2;

  // PROGRAM COUNTER
  wire [31:0] pc, pc_next;

  assign IMEM_ARADDR = pc;

  // ************ UNITS *****************

  // * ALU UNIT
  alu #() alu_t (.ALU_CID(alu_cid), .ALU_I1(alu_i1),
  .ALU_I2(alu_i2), .ALU_O(alu_o));

  // * CONTROL UNIT
  control #() control_t (
    // ALU CONTROL
    .ALU_CID(alu_cid), .ALU_I1(alu_i1), .ALU_I2(alu_i2), .ALU_O(alu_o),
    // REGISTER READ / WRITE
    .REG_AWVALID(reg_awvalid), .REG_WDATA(reg_wr_data),  .REG_AWADDR(reg_wr_idx),
    .REG_ARADDR1(reg_rd_idx1), .REG_ARADDR2 (reg_rd_idx2), .REG_RDATA1(reg_rd_data1), .REG_RDATA2(reg_rd_data2),
    // PROGRAM COUNTER
    .PC(pc), .PC_N(pc_next),
    // DATA MEMORY
    .DMEM_RDATA(DMEM_ARADDR), .DMEM_ARADDR(DMEM_ARADDR),
    .DMEM_AWVALID(DMEM_AWVALID), .DMEM_WDATA(DMEM_WDATA), .DMEM_AWADDR(DMEM_AWADDR),
    // INSTRUCTION MEMORY
    .IMEM_RDATA(IMEM_RDATA)
    );

  // * PC
  single_ff #(.WIDTH(32), .NRST_VAL(0)) pc_t (
    .CLK(CLK), .NRST(NRST), .D(pc_next), .Q(pc));


  // * REGISTERS
  registers #() registers_t (.CLK(CLK), .NRST(NRST), // Sys
  .AWVALID(reg_awvalid), .WDATA(reg_wr_data), .AWID(reg_wr_idx), // Write
  .ARID1(reg_rd_idx1), .ARID2(reg_rd_idx2), .RDATA1(reg_rd_data1), .RDATA2(reg_rd_data2)); // Read

endmodule
