`timescale 1ns / 10ps
`include "define.vh"

/**
TOP control module must
- Keep track of the current state we're in
- Drive signals for each cpu part to do its thing
	- instruction fetch
	- instruction decode
	- ALU calculation / load or store instruction
	- PC increment
*/

module core_control #(
) (
    input    CLK, NRST,
    // *** INSTRUCTION FETCH SIGNALS
    input [31:0]  INSTRUCTION,
    input [31:0]  PC,

    // *** REGISTER SIGNALS
    output [ 4:0] REG_ARADDR1,  // Which read register 1 to use
    output [ 4:0] REG_ARADDR2,  // Which read register 2 to use
    output reg [ 4:0] memwb_reg_awaddr,   // Which register to write to
    input  [31:0] REG_RDATA1,
    input  [31:0] REG_RDATA2,

    // *** GENERAL
    output reg [31:0] memwb_imm,

    // *** ALU SIGNALS
    output [3:0] OPCODE_ALU,
    output reg [31:0] idex_imm,
    output reg  idex_c_isimm,   // Shows whether its an immediate instruction or not => Used by alu when selecting REG2 vs immediate

    // *** MEMORY SIGNALS
    output [31:0] DMEM_ADDR,  // Determines load / store address
    output ISLOADBS,
    output ISLOADHWS,
    output [3:0] STRB,

    // *** INSTRUCTION MEMORY AXI SIGNALS
    // And for read valid
    input IMEM_AXI_RVALID,
    input IMEM_AXI_ARREADY,

    // *** DATA MEMORY AXI SIGNALS
    // Write valid
    input HOST_AXI_RVALID,
    input HOST_AXI_RREADY,
    // Read valid
    input HOST_AXI_BVALID,
    input HOST_AXI_BREADY,

    // *** CONTROL SIGNALS
    // Instruction fetch should always happen unless stall happens.
    // And make the imem finish to avoid occupying the bus continuously in case of a memory fetch.
    // PC Should be updated every clock-cycle if not in stall-mode.
    output HCU_STALLPIPE,
    output reg [3:0] memwb_c_wb_code,
    output reg  memwb_c_reg_awvalid,
    output reg  exmem_c_doload,
    output reg  exmem_c_dostore,
    output reg  idex_c_alu
);

  // DECODER SIGNALS;
  wire [2:0] funct3;
  wire [6:0] funct7;
  wire [31:0] imm_dec;
  wire [6:0] opcode;


  // CONTROL SIGNALS
  wire c_branch, c_cmem, c_isimm, c_alu, c_dostore, c_doload, c_reg_awvalid;
  wire [3:0] c_wb_code;
  wire [3:0] reg_awaddr;

  core_idecode core_idecode_inst (
      .CLK(CLK),
      .NRST(NRST),
      .INSTRUCTION(INSTRUCTION),
      .OPCODE(opcode),
      .FUNCT3(funct3),
      .FUNCT7(funct7),
      .C_ISIMM(c_isimm),
      .IMM_DEC(imm_dec),
      .C_ALU(c_alu),
      .C_BRANCH(c_branch),
      .C_DOLOAD(c_doload),
      .C_DOSTORE(c_dostore),
      .C_WB_CODE(c_wb_code),
      .C_REG_AWVALID(c_reg_awvalid),
      .C_CMEM(c_cmem),
      .REG_ARADDR1(REG_ARADDR1), // Do not save as intermediate -> address only needed in next stage
      .REG_ARADDR2(REG_ARADDR2),
      .REG_AWADDR(reg_awaddr)
  );

  core_calu core_calu_inst (
      .OPCODE(opcode_latched),
      .FUNCT3(funct3),
      .FUNCT7(funct7),
      .IMM(imm_dec),
      .ISIMM(idex_c_isimm),
      .OPCODE_ALU(OPCODE_ALU)
  );

  wire c_take_branch;
  core_cbranch core_cbranch_inst (
      .NRST(NRST),
      .CLK(CLK),
      .C_BRANCH(idex_c_branch),
      .FUNCT3(funct3),
      .REG_RDATA1(idex_reg_rdata1),
      .REG_RDATA2(idex_reg_rdata2),
      .TAKE_BRANCH(c_take_branch)
  );

  core_cmem core_cmem_inst (
      .CLK(CLK),
      .NRST(NRST),
      .C_CMEM(idex_c_cmem),
      .OPCODE(opcode_latched),
      .PC(PC),
      .IMM(idex_imm),
      .REG_RDATA1(idex_reg_rdata1),
      .FUNCT3(funct3),
      .DMEM_ADDR(DMEM_ADDR),
      .ISLOADBS(ISLOADBS),
      .ISLOADHWS(ISLOADHWS),
      .STRB(STRB)
  );

  reg [6:0] opcode_latched;

  always @(posedge CLK) begin
    opcode_latched <= opcode;
  end

  // ==============================================
  // HCU
  // ==============================================
  /**
  FLUSH:
  - Can only occur on condition of instruction at the WB stage.
  - Conditions (JAL, JALR, BRANCH_TAKEN, LUI, AUIPC)
  - On flush:
    - Clear all control signals in the pipeline.
  STALL:
  - Can only occur on condition of instruction at the IFETCH-busy, MEM-busy case
  - Conditions to unblock (c_imem_done latched AND c_mem_done latched -> true)
  - on stall:
    - PC should NOT be updated
    - Pipeline registers should NOT be updated
    - Disable the store and load signals on stall (they should only be valid for one clock cycle)
      - Make sure to latch the signals inside the modules until a response arrived
  HAZARDS:
  - Data hazard: instruction depends on data to be written into register by earlier (uncompleted) instruction
    - Solution 1: stalling pipeline until result is available? -> Inserting fake instruction with no control signals
        - Detect in the ID stage and stall for 1 cycle
    - Solution 2: forwarding
  - Control hazard: instruction fetches invalidated due to jumps / branches
    - Solution 1: Pipeline stalling (simple stall)
    - Solution 2: forwarding

  //! WARNING: hazard checks need to be performed on the waddr coming from the cmem-control,
  //           these values are formed in the exec stage, so we might need to forward here.
  //! WARNING: atm the DMEM_ADDR is latched, and the immediate is latched as well.
  //           Perhaps its better to latch the immediate through the pipeline registers and simply form the dmem_addr as a comb in the exec stage
  // C_MEM_DONE (memory store load), IFETCH_DONE should decide on stalling pipeline
  // JAL(R) / BRANCH -> should flush the instructions before
  // Make sure to enable these signals when
  */
  wire c_imem_done, c_mem_done;
  assign c_imem_done = IMEM_AXI_RVALID & IMEM_AXI_ARREADY;
  assign c_mem_done = ((HOST_AXI_RREADY & HOST_AXI_RVALID) | (HOST_AXI_BVALID & HOST_AXI_BREADY));


  wire hcu_flushhpipe;
  // ==============================================
  // REGISTERS
  // ==============================================
  // Fetch -> Instruction Decode

  // *** ID stage ***
  reg [31:0] idex_pc, idex_reg_rdata1, idex_reg_rdata2; // PC Carry
  reg [4:0] idex_reg_awaddr;

  // SIGNALS
  reg [3:0] idex_c_wb_code;
  reg idex_c_doload, idex_c_dostore;
  reg idex_c_branch, idex_c_cmem, idex_c_reg_awvalid;

  // *** EXECUTE STAGE ***
  reg [31:0] exmem_imm, exmem_reg_rdata1, exmem_reg_rdata2;  // (store, load)
  reg [4:0] exmem_reg_awaddr;   // (store, load)
  reg       exmem_c_take_branch, exmem_c_reg_awvalid;
  reg [3:0] exmem_c_wb_code; //! WARNING: Adaptation is needed here if branch is taken

  // *** WRITE BACK STAGE ***
  reg memwb_c_take_branch;

  // *** SYNCHRONOUS LOGIC ***
  // IDEX
  always @(posedge CLK)
  begin
    if (hcu_flushhpipe)
    begin
      // Set all control signals equal to zero
      // Set the program counter to the value indicated by the wb instruction

    end
    if (!HCU_STALLPIPE) // MAKE SURE
    begin
      //! IDEX
      // IF R-alu or I-alu or Store or Load
      idex_reg_rdata1 <= REG_RDATA1;
      idex_reg_rdata2 <= REG_RDATA2;
      idex_reg_awaddr <= reg_awaddr;
      // IF branching
      idex_imm <= imm_dec;
      idex_c_isimm <= c_isimm;
      // CONTROL SIGNALS
      idex_c_branch <= c_branch;
      idex_c_alu <= c_alu;
      idex_c_doload <= c_doload;
      idex_c_dostore <= c_dostore;
      idex_c_wb_code <= c_wb_code;
      idex_c_reg_awvalid <= c_reg_awvalid;
      idex_c_cmem <= c_cmem;

      //! EXMEM
      // if store / load instruction
      exmem_reg_rdata2 <= idex_reg_rdata2;
      exmem_reg_awaddr <= idex_reg_awaddr;
      // IF branching store / load
      exmem_imm <= imm_dec;
      exmem_c_take_branch <= c_take_branch;
      exmem_c_doload <= idex_c_doload;
      exmem_c_dostore <= idex_c_dostore;
      exmem_c_reg_awvalid <= idex_c_reg_awvalid;
      exmem_c_wb_code <= idex_c_wb_code;
      //! MEMWB
      // For any instruction except branch and store (since no write to register is done there)
      memwb_reg_awaddr <= exmem_reg_awaddr;
      memwb_c_take_branch <= exmem_c_take_branch;
      // For any instruction where the PC is changed using imm
      memwb_imm <= exmem_imm;
      memwb_c_reg_awvalid <= exmem_c_reg_awvalid;
      memwb_c_wb_code <= exmem_c_wb_code;
    end
    else;
  end

endmodule

/**
So obviously when the pipe is stalled no new instruction fetches may happen and no memory writes may happen.
That means that I need some kind-of way to signal to my memory module and my instruction fetcher to stop fetching / stop incrementing the program counter.
What I thought is to simply send the CPU_STALL signal, when the CPU_STALL is disabled the PC will always increment and the memory modules will latch the dofetch-signal until the fetching is done. When the CPU_STALL is disabled they won't.
Is this the normal way of doing things? Or is it better to have a single IFETCH, PC_INCR and enable them from central cpu-command unless the stall is enabled?
*/