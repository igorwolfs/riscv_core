`timescale 1ns/10ps

/**


The program counter needs to be updated on every clock cycle.
- PC+4 (normally)
- PC+other_number (depending on )
*/


module core
  (
  input  sysclk, nrst_in
  );
  // ALU COMMANDS
  wire alu_cid, alu_arg1_in, alu_arg2_in, alu_arg_out;

  // REGISTER READ / WRITE
  wire reg_wr_en;
  wire [4:0] reg_wr_idx, reg_rd_idx1, reg_rd_idx2;
  wire [31:0] reg_wr_data, reg_rd_data1, reg_rd_data2;

  // PROGRAM COUNTER
  wire [31:0] pc, pc_next;

  // DATA MEMORY
  wire [31:0] dmem_rd_data;
  wire [31:0] dmem_rd_idx;
  wire [31:0] dmem_wr_idx;
  wire [31:0] dmem_wr_data;
  wire dmem_wr_en, dmem_read;

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
    .wr_en(wr_en), .wr_idx_in(wr_idx), .rd_idx1_in(rd_idx1), .rd_idx2_in (rd_idx2),
    .wr_data_in(wr_data), .rd_data_1_out(rd_data_1), .rd_data_2_out(rd_data_2),
    // PROGRAM COUNTER
    .pc(pc), .pc_next(pc_next),
    // DATA MEMORY
    .dmem_in(dmem_in), .dmem_addr_out(dmem_addr_out),
    // INSTRUCTION MEMORY
    .imem_in(imem_instr)
    );

  // * DATA MEMORY
  dmemory #() dmemory_t (.clkin(sysclk), .nrst_in(nrst_in),
  .wr_en_in(dmem_wr_en), .wr_idx_in(dmem_wr_idx), .wr_data_in(dmem_wr_data), // WRITE
  .rd_idx_in(dmem_rd_idx), .rd_data_out(dmem_rd_data));

  // * INSTRUCTION MEMORY
  /*
  Program counter: on clock out -> program counter is set to pc_next acquired from control-unit.
  Program counter is then used in instruction memory fetch.
  */
  double_ff_sync #(.WIDTH(32), .NRST_VAL(0)) pc_t (
    .clkin(sysclk), .nrst_in(nrst_in), .data_in(pc_next), .data_out(pc));

  // Instruction memory
  imemory #() imemory_t (.clkin(sysckl),
  .rd_idx_in(pc), .rd_data_out(imem_instr));

  // * REGISTERS
  registers #() registers_t (.clkin(sysclk), .nrst_in(nrst_in), // Sys
  .wr_en(reg_wr_en), .wr_data_in(reg_wr_data), .wr_idx_in(reg_wr_idx), // Write
  .rd_idx1_in(reg_rd_idx1), .rd_idx2_in(reg_rd_idx2), .rd_data1_out(reg_rd_data1), .rd_data2_out(reg_rd_data2)); // Read

endmodule
