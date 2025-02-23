`timescale 1ns/10ps

/**


The program counter needs to be updated on every clock cycle.
- PC+4 (normally)
- PC+other_number (depending on )
*/


module core #(
              // INTERNAL MEMORY TO INTERFACE WITH
              parameter INTERNAL_MEMORY = 1'b1)
  (
    // SYSTEM
    input  sysclk, nrst_in,

    // External memory interface (when INTERNAL_MEMORY = 0)
    // Data Memory Interface
    output wire [31:0] dmem_rd_addr,
    input  wire [31:0] dmem_rd_data,
    output wire [31:0] dmem_wr_addr,
    output wire [31:0] dmem_wr_data,
    output wire        dmem_wr_en,
    
    // Instruction Memory Interface
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_data
  );

  // Internal signals
  wire [31:0] internal_dmem_rd_data;
  wire [31:0] internal_imem_data;

  // ALU COMMANDS
  wire [31:0] alu_arg1_in, alu_arg2_in, alu_arg_out;
  wire [9:0] alu_cid;

  // REGISTER READ / WRITE
  wire reg_wr_en;
  wire [4:0] reg_wr_idx, reg_rd_idx1, reg_rd_idx2;
  wire [31:0] reg_wr_data, reg_rd_data1, reg_rd_data2;

  // PROGRAM COUNTER
  wire [31:0] pc, pc_next;

  // Memory multiplexing based on INTERNAL_MEMORY parameter
  wire [31:0] active_dmem_rd_data = INTERNAL_MEMORY ? internal_dmem_rd_data : dmem_rd_data;
  wire [31:0] active_imem_data = INTERNAL_MEMORY ? internal_imem_data : imem_data;

  // INSTRUCTION MEMORY
  wire [31:0] imem_instr;

  // ************ UNITS *****************

  // * ALU UNIT
  alu #() alu_t (.alu_cid_in(alu_cid), .alu_arg1_in(alu_arg1_in),
  .alu_arg2_in(alu_arg2_in), .alu_arg_out(alu_arg_out));

  // * CONTROL UNIT
  control #() control_t (
    // ALU CONTROL
    .alu_cid_out(alu_cid), .alu_arg1_out(alu_arg1_in), .alu_arg2_out(alu_arg2_in), .alu_arg_in(alu_arg_out),
    // REGISTER READ / WRITE
    .reg_wr_en_out(reg_wr_en), .reg_wr_data_out(reg_wr_data),  .reg_wr_idx_out(reg_wr_idx),
    .reg_rd_idx1_out(reg_rd_idx1), .reg_rd_idx2_out (reg_rd_idx2), .reg_rd_data1_in(reg_rd_data1), .reg_rd_data2_in(reg_rd_data2),
    // PROGRAM COUNTER
    .pc(pc), .pc_next(pc_next),
    // DATA MEMORY
    .dmem_rd_data_in(active_dmem_rd_data), .dmem_rd_addr_out(dmem_rd_addr),
    .dmem_wr_en_out(dmem_wr_en), .dmem_wr_data_out(dmem_wr_data), .dmem_wr_addr_out(dmem_wr_addr),
    // INSTRUCTION MEMORY
    .imem_in(active_imem_data)
    );


    // Generate block for internal/external memory selection
    generate
      if (INTERNAL_MEMORY) begin : internal_memory
          // Internal Data Memory
          dmemory #() dmemory_t (
              .clkin(sysclk),
              .nrst_in(nrst_in),
              .rd_data_out(internal_dmem_rd_data),
              .rd_addr_in(dmem_rd_addr),
              .wr_en_in(dmem_wr_en),
              .wr_data_in(dmem_wr_data),
              .wr_addr_in(dmem_wr_addr)
          );

          // Internal Instruction Memory
          imemory #() imemory_t (
              .clkin(sysclk),
              .rd_addr_in(pc),
              .rd_data_out(internal_imem_data)
          );
      end
  endgenerate

  // Program counter
  single_ff #(.WIDTH(32), .NRST_VAL(0)) pc_t (
    .clkin(sysclk), .nrst_in(nrst_in), .data_in(pc_next), .data_out(pc));

  assign imem_addr = pc;

  // * REGISTERS
  registers #() registers_t (.clkin(sysclk), .nrst_in(nrst_in), // Sys
  .wr_en(reg_wr_en), .wr_data_in(reg_wr_data), .wr_idx_in(reg_wr_idx), // Write
  .rd_idx1_in(reg_rd_idx1), .rd_idx2_in(reg_rd_idx2), .rd_data1_out(reg_rd_data1), .rd_data2_out(reg_rd_data2)); // Read

endmodule
