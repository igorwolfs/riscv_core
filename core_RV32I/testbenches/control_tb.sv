`timescale 1ns/10ps

module control_tb();

// -------------------- DUT I/O --------------------
reg  [31:0] alu_arg_in;        // ALU input
reg  [31:0] REG_RDATA1;   // Register read data 1
reg  [31:0] REG_RDATA2;   // Register read data 2
reg  [31:0] pc;                // Current PC
reg  [31:0] DMEM_RDATA;   // Data memory read data
reg  [31:0] IMEM_RDATA;           // Instruction memory data (the instruction)

wire [9:0] ALU_O;       // Some ALU control bit
wire [31:0] ALU_I1;
wire [31:0] alu_I2;

wire        REG_AWVALID;
wire [4:0]  REG_WDATA;
wire [4:0]  REG_ARADDR1;
wire [4:0]  REG_ARADDR2;
wire [31:0] REG_WDATA;

wire [31:0] pc_next;

wire [31:0] DMEM_ARADDR;
wire        DMEM_AWVALID;
wire [31:0] DMEM_WDATA;
wire [31:0] DMEM_AWADDR;


// ---2----------------- DUT Instance --------------------
control #() control_dut (
    // ALU
    .ALU_O      (ALU_O),
    .ALU_I1     (ALU_I1),
    .alu_I2     (alu_I2),
    .alu_arg_in       (alu_arg_in),

    // Register R/W
    .REG_AWVALID    (REG_AWVALID),
    .REG_WDATA   (REG_WDATA),
    .REG_ARADDR1  (REG_ARADDR1),
    .REG_ARADDR2  (REG_ARADDR2),
    .REG_WDATA  (REG_WDATA),
    .REG_RDATA1  (REG_RDATA1),
    .REG_RDATA2  (REG_RDATA2),

    // PC
    .pc               (pc),
    .pc_next          (pc_next),

    // Data Memory
    .DMEM_RDATA  (DMEM_RDATA),
    .DMEM_ARADDR (DMEM_ARADDR),
    .DMEM_AWVALID   (DMEM_AWVALID),
    .DMEM_WDATA (DMEM_WDATA),
    .DMEM_AWADDR (DMEM_AWADDR),

    // Instruction Memory
    .IMEM_RDATA          (IMEM_RDATA)
);

// -------------------- Test Stimulus --------------------
initial begin
    // Use $timeformat if you want human-readable simulation times
    $timeformat(-9, 1, " ns", 6);

    // Initialize signals
    alu_arg_in       = 32'hDEAD_BEEF;
    REG_RDATA1  = 32'h0000_0000;
    REG_RDATA2  = 32'h0000_0000;
    pc               = 32'h0000_0100;
    DMEM_RDATA  = 32'h0000_0000;
    IMEM_RDATA          = 32'h0000_0000;

    // Let signals settle
    #10;

    // ------------------------------------------
    // Example 1: R-type ADD x3, x1, x2
    //  7  bits   5 bits 5 bits 3 bits 5 bits 7 bits
    // funct7   rs2   rs1   funct3  rd   opcode
    // 0000000  00010 00001 000     00011 0110011  => 0x00208133
    // (Add x3 <- x1 + x2)
    // 
    // Let’s say REG_RDATA1=10, REG_RDATA2=20
    //
    IMEM_RDATA         = 32'b0000000_00010_00001_000_00011_0110011; // 0x00208133
    REG_RDATA1 = 32'd10;
    REG_RDATA2 = 32'd20;
    pc              = 32'h0000_0100;
    #10;
    $display("[R-type ADD] time=%t", $realtime);
    $display("  Instr   = 0x%08h", IMEM_RDATA);
    $display("  REG_AWVALID   = %b",    REG_AWVALID);
    $display("  REG_WDATA  = %d",    REG_WDATA);
    $display("  ALU_I1    = %d",    ALU_I1);
    $display("  alu_I2    = %d",    alu_I2);
    $display("  pc_next         = 0x%08h", pc_next);

    // ------------------------------------------
    // Example 2: I-type ADDI x3, x1, 0x10
    //  12 bits 5 bits 3 bits 5 bits 7 bits
    // imm[11:0] rs1 funct3 rd opcode (I-type)
    // 00010000  00001 000   00011 0010011 => 0x01008193
    // (Addi x3 = x1 + 0x10)
    IMEM_RDATA         = 32'h01008193;
    REG_RDATA1 = 32'd100;  // Suppose x1=100
    REG_RDATA2 = 32'd999;  // Should be ignored for ADDI
    pc              = 32'h0000_0104;
    #10;
    $display("[I-type ADDI] time=%t", $realtime);
    $display("  Instr   = 0x%08h", IMEM_RDATA);
    $display("  REG_AWVALID   = %b",    REG_AWVALID);
    $display("  REG_WDATA  = %d",    REG_WDATA);
    $display("  ALU_I1    = %d",    ALU_I1);
    $display("  alu_I2    = %d",    alu_I2);
    $display("  pc_next         = 0x%08h", pc_next);

    // ------------------------------------------
    // Example 3: BEQ x1, x2, offset -> test branching
    //  7 bits 5 bits 5 bits 3 bits 5 bits 7 bits
    // imm[12|10:5] rs2  rs1  funct3 imm[4:1|11] opcode  => typical B-type
    // Suppose we do: beq x1, x2, offset=8
    // offset=8 in B-type has a certain bit structure, but let's do a rough test
    IMEM_RDATA         = 32'b000000_00010_00001_000_00000_1100011; // just an example
    REG_RDATA1 = 32'd50;
    REG_RDATA2 = 32'd50;  // Should be equal => branch taken
    pc              = 32'h0000_0108;
    #10;
    $display("[B-type BEQ] time=%t", $realtime);
    $display("  Instr   = 0x%08h", IMEM_RDATA);
    $display("  pc_next         = 0x%08h (branch taken?)", pc_next);

    // ------------------------------------------
    // Add more stimuli as you like...
    // Wait a bit then stop.
    #50;
    $finish;
end
endmodule
