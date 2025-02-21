`timescale 1ns/10ps

module control_tb();

// -------------------- DUT I/O --------------------
reg  [31:0] alu_arg_in;        // ALU input
reg  [31:0] reg_rd_data1_in;   // Register read data 1
reg  [31:0] reg_rd_data2_in;   // Register read data 2
reg  [31:0] pc;                // Current PC
reg  [31:0] dmem_rd_data_in;   // Data memory read data
reg  [31:0] imem_in;           // Instruction memory data (the instruction)

wire [9:0] alu_cid_out;       // Some ALU control bit
wire [31:0] alu_arg1_out;
wire [31:0] alu_arg2_out;

wire        reg_wr_en_out;
wire [4:0]  reg_wr_idx_out;
wire [4:0]  reg_rd_idx1_out;
wire [4:0]  reg_rd_idx2_out;
wire [31:0] reg_wr_data_out;

wire [31:0] pc_next;

wire [31:0] dmem_rd_addr_out;
wire        dmem_wr_en_out;
wire [31:0] dmem_wr_data_out;
wire [31:0] dmem_wr_addr_out;


// ---2----------------- DUT Instance --------------------
control #() control_dut (
    // ALU
    .alu_cid_out      (alu_cid_out),
    .alu_arg1_out     (alu_arg1_out),
    .alu_arg2_out     (alu_arg2_out),
    .alu_arg_in       (alu_arg_in),

    // Register R/W
    .reg_wr_en_out    (reg_wr_en_out),
    .reg_wr_idx_out   (reg_wr_idx_out),
    .reg_rd_idx1_out  (reg_rd_idx1_out),
    .reg_rd_idx2_out  (reg_rd_idx2_out),
    .reg_wr_data_out  (reg_wr_data_out),
    .reg_rd_data1_in  (reg_rd_data1_in),
    .reg_rd_data2_in  (reg_rd_data2_in),

    // PC
    .pc               (pc),
    .pc_next          (pc_next),

    // Data Memory
    .dmem_rd_data_in  (dmem_rd_data_in),
    .dmem_rd_addr_out (dmem_rd_addr_out),
    .dmem_wr_en_out   (dmem_wr_en_out),
    .dmem_wr_data_out (dmem_wr_data_out),
    .dmem_wr_addr_out (dmem_wr_addr_out),

    // Instruction Memory
    .imem_in          (imem_in)
);

// -------------------- Test Stimulus --------------------
initial begin
    // Use $timeformat if you want human-readable simulation times
    $timeformat(-9, 1, " ns", 6);

    // Initialize signals
    alu_arg_in       = 32'hDEAD_BEEF;
    reg_rd_data1_in  = 32'h0000_0000;
    reg_rd_data2_in  = 32'h0000_0000;
    pc               = 32'h0000_0100;
    dmem_rd_data_in  = 32'h0000_0000;
    imem_in          = 32'h0000_0000;

    // Let signals settle
    #10;

    // ------------------------------------------
    // Example 1: R-type ADD x3, x1, x2
    //  7  bits   5 bits 5 bits 3 bits 5 bits 7 bits
    // funct7   rs2   rs1   funct3  rd   opcode
    // 0000000  00010 00001 000     00011 0110011  => 0x00208133
    // (Add x3 <- x1 + x2)
    // 
    // Let’s say reg_rd_data1_in=10, reg_rd_data2_in=20
    //
    imem_in         = 32'b0000000_00010_00001_000_00011_0110011; // 0x00208133
    reg_rd_data1_in = 32'd10;
    reg_rd_data2_in = 32'd20;
    pc              = 32'h0000_0100;
    #10;
    $display("[R-type ADD] time=%t", $realtime);
    $display("  Instr   = 0x%08h", imem_in);
    $display("  reg_wr_en_out   = %b",    reg_wr_en_out);
    $display("  reg_wr_idx_out  = %d",    reg_wr_idx_out);
    $display("  alu_arg1_out    = %d",    alu_arg1_out);
    $display("  alu_arg2_out    = %d",    alu_arg2_out);
    $display("  pc_next         = 0x%08h", pc_next);

    // ------------------------------------------
    // Example 2: I-type ADDI x3, x1, 0x10
    //  12 bits 5 bits 3 bits 5 bits 7 bits
    // imm[11:0] rs1 funct3 rd opcode (I-type)
    // 00010000  00001 000   00011 0010011 => 0x01008193
    // (Addi x3 = x1 + 0x10)
    imem_in         = 32'h01008193;
    reg_rd_data1_in = 32'd100;  // Suppose x1=100
    reg_rd_data2_in = 32'd999;  // Should be ignored for ADDI
    pc              = 32'h0000_0104;
    #10;
    $display("[I-type ADDI] time=%t", $realtime);
    $display("  Instr   = 0x%08h", imem_in);
    $display("  reg_wr_en_out   = %b",    reg_wr_en_out);
    $display("  reg_wr_idx_out  = %d",    reg_wr_idx_out);
    $display("  alu_arg1_out    = %d",    alu_arg1_out);
    $display("  alu_arg2_out    = %d",    alu_arg2_out);
    $display("  pc_next         = 0x%08h", pc_next);

    // ------------------------------------------
    // Example 3: BEQ x1, x2, offset -> test branching
    //  7 bits 5 bits 5 bits 3 bits 5 bits 7 bits
    // imm[12|10:5] rs2  rs1  funct3 imm[4:1|11] opcode  => typical B-type
    // Suppose we do: beq x1, x2, offset=8
    // offset=8 in B-type has a certain bit structure, but let's do a rough test
    imem_in         = 32'b000000_00010_00001_000_00000_1100011; // just an example
    reg_rd_data1_in = 32'd50;
    reg_rd_data2_in = 32'd50;  // Should be equal => branch taken
    pc              = 32'h0000_0108;
    #10;
    $display("[B-type BEQ] time=%t", $realtime);
    $display("  Instr   = 0x%08h", imem_in);
    $display("  pc_next         = 0x%08h (branch taken?)", pc_next);

    // ------------------------------------------
    // Add more stimuli as you like...
    // Wait a bit then stop.
    #50;
    $finish;
end
endmodule
