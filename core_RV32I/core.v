`timescale 1ns/10ps

`include "config.vh"
/**


The program counter needs to be updated on every clock cycle.
- PC+4 (normally)
- PC+other_number (depending on )
*/


module core #(parameter INTERNAL_MEMORY=1'b1)
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

  // Memory multiplexing based on INTERNAL_MEMORY parameter
  wire [31:0] active_dmem_rdata = INTERNAL_MEMORY ? internal_dmem_rdata : DMEM_RDATA;
  wire [31:0] active_imem_rdata = INTERNAL_MEMORY ? internal_imem_rdata : IMEM_RDATA;

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
    .DMEM_RDATA(active_dmem_rdata), .DMEM_ARADDR(DMEM_ARADDR),
    .DMEM_AWVALID(DMEM_AWVALID), .DMEM_WDATA(DMEM_WDATA), .DMEM_AWADDR(DMEM_AWADDR),
    // INSTRUCTION MEMORY
    .IMEM_RDATA(active_imem_rdata)
    );


  // Generate block for internal/external memory selection
  generate
    if (INTERNAL_MEMORY) begin : internal_memory
    // Internal Data Memory
    dmemory #() dmemory_t (
        .CLK(CLK),
        .NRST(NRST),
        .RDATA(internal_dmem_rdata),
        .ARADDR(DMEM_ARADDR),
        .AWVALID(DMEM_AWVALID),
        .WDATA(DMEM_WDATA),
        .AWADDR(DMEM_AWADDR)
    );

    // Internal Instruction Memory
    imemory #() imemory_t (
        .CLK(CLK),
        .ARADDR(pc),
        .RDATA(internal_imem_rdata)
    );
    end
  endgenerate

  // * PC
  single_ff #(.WIDTH(32), .NRST_VAL(0)) pc_t (
    .CLK(CLK), .NRST(NRST), .D(pc_next), .Q(pc));

  assign IMEM_ARADDR = pc;

  // * REGISTERS
  registers #() registers_t (.CLK(CLK), .NRST(NRST), // Sys
  .AWVALID(reg_awvalid), .WDATA(reg_wr_data), .AWID(reg_wr_idx), // Write
  .ARID1(reg_rd_idx1), .ARID2(reg_rd_idx2), .RDATA1(reg_rd_data1), .RDATA2(reg_rd_data2)); // Read

endmodule
