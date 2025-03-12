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
    output [ 4:0] REG_AWADDR,   // Which register to write to
    input  [31:0] REG_RDATA1,
    input  [31:0] REG_RDATA2,

    // *** GENERAL
    output [31:0] IMM,
    // *** ALU SIGNALS
    output [3:0]  OPCODE_ALU,
    output			  ISIMM, 	// Shows whether its an immediate instruction or not => Used by alu when selecting REG2 vs immediate
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
    output      C_INSTR_FETCH,
    output      C_PC_UPDATE,
    output [3:0] C_WB_CODE,
    output      C_REG_AWVALID,
    output      C_DOLOAD,
    output      C_DOSTORE,
    output      C_ALU
);

  // DECODER SIGNALS;
  wire [2:0] funct3;
  wire [6:0] funct7;
  wire [31:0] imm_dec;
  wire [6:0] opcode;

  // BRANCHING SIGNALS
  wire c_take_branch;

  // CONTROL SIGNALS
  wire c_branch, c_decode, c_cmem;

  core_idecode core_idecode_inst (
      .CLK(CLK),
      .NRST(NRST),
      .INSTRUCTION(INSTRUCTION),
      .C_DECODE(c_decode),
      .OPCODE(opcode),
      .FUNCT3(funct3),
      .FUNCT7(funct7),
      .IMM_DEC(imm_dec),
      .ISIMM(ISIMM),
      .REG_ARADDR1(REG_ARADDR1),
      .REG_ARADDR2(REG_ARADDR2),
      .REG_AWADDR(REG_AWADDR)
  );

  wire [31:0] alu_imm;
  core_calu core_calu_inst (
      .OPCODE(opcode_latched),
      .FUNCT3(funct3),
      .FUNCT7(funct7),
      .IMM(imm_dec),
      .ISIMM(ISIMM),
      .ALU_IMM(alu_imm),
      .OPCODE_ALU(OPCODE_ALU)
  );

  core_cbranch core_cbranch_inst (
      .NRST(NRST),
      .CLK(CLK),
      .C_BRANCH(c_branch),
      .FUNCT3(funct3),
      .REG_RDATA1(REG_RDATA1),
      .REG_RDATA2(REG_RDATA2),
      .TAKE_BRANCH(c_take_branch)
  );

  core_cmem core_cmem_inst (
      .CLK(CLK),
      .NRST(NRST),
      .C_CMEM(c_cmem),
      .OPCODE(opcode_latched),
      .PC(PC),
      .IMM(imm_dec),
      .REG_RDATA1(REG_RDATA1),
      .FUNCT3(funct3),
      .DMEM_ADDR(DMEM_ADDR),
      .ISLOADBS(ISLOADBS),
      .ISLOADHWS(ISLOADHWS),
      .STRB(STRB)
  );

  assign IMM = (C_ALU & (opcode == `OPCODE_I_ALU)) ? alu_imm : imm_dec;

  reg [6:0] opcode_latched;

  always @(posedge CLK) begin
    opcode_latched <= opcode;
  end

  // ==============================================
  // REGISTERS
  // ==============================================
  // Fetch -> Instruction Decode
  reg [31:0] fid_pc;
  reg [31:0] fid_instruction;

  always @(posedge CLK)
  begin
    if (NRST)
    begin
      // FID
      fid_pc <= 32'hDEADBEEF;
      fid_instruction <= 32'hDEADBEEF;
    end
    else
    begin
      // FID
      if (C_PC_UPDATE)
        fid_pc <= PC;
      fid_instruction <= INSTRUCTION;
      // IDEX
    end
  end

  // *** ID stage ***
  // Instruction Decode -> Execute
  // Instruction decode -> WB (JAL, JALR, LUI, AUIPC)
  reg [31:0] idex_pc; // PC carry
  reg [31:0] idex_rdata1;
  reg [31:0] idex_rdata2;
  reg [2:0] idex_funct3;
  reg [6:0] idex_funct7;
  reg idex_isimm;
  reg [31:0] idex_imm;
  reg [4:0] idex_awaddr;


  // *** EXECUTE STAGE ***
  // Execute -> WB
  reg [31:0] exmem_pc; // (all -> Note the PC will be +4 automatically, and should be flushed in other cases)
  reg [4:0] exmem_awaddr; // (store, load, alu, jump, lui, jal(r))
  reg [31:0] exmem_alu; // (alu)
  reg exmem_take_branch; // (branch)

  // Execute -> MEM
  reg [31:0] exmem_rdata1; // (store, load)
  reg [31:0] exmem_rdata2; // (store, load)
  reg [4:0] exmem_awaddr; // (store, load, )
  reg [31:0] exmem_memaddr; // (store, load)
  reg exmem_isloadbs;
  reg exmem_isloadhws;
  reg [3:0] exmem_strb;

  // *** MEMORY STAGE ***
  // Memory -> WB
  reg [31:0] memwb_pc; // pc carry
  reg [4:0] memwb_awaddr // register write address carry
  reg [31:0] memwb_rdata;

  // ==============================================
  // CENTRAL SM PIPELINE CONTROL
  // ==============================================

  wire c_imem_done, c_mem_done;
  assign c_imem_done = IMEM_AXI_RVALID & IMEM_AXI_ARREADY;
  assign c_mem_done = ((HOST_AXI_RREADY & HOST_AXI_RVALID) | (HOST_AXI_BVALID & HOST_AXI_BREADY));

    pipeline_control pipeline_control_inst (
      .C_INSTR_FETCH(C_INSTR_FETCH),
      .C_ALU(C_ALU),
      .C_DECODE(c_decode),
      .C_REG_AWVALID(C_REG_AWVALID),
      .C_CMEM(c_cmem),
      .C_DOSTORE(C_DOSTORE),
      .C_DOLOAD(C_DOLOAD),
      .C_BRANCH(c_branch),
      .C_PC_UPDATE(C_PC_UPDATE),
      .C_WB_CODE(C_WB_CODE),
      .CLK(CLK),
      .NRST(NRST),
      .C_IMEM_DONE(c_imem_done),
      .C_MEM_DONE(c_mem_done),
      .C_TAKE_BRANCH(c_take_branch),
      .OPCODE(opcode)
    );

endmodule


/** EXEC **
IF BRANCH INSTRUCTION
- Check branching condition
- Make sure the brancher module says the branch was (in)valid
- go to S_WB (where you increment pc)
IF ALU INSTRUCTION
- Drive ALU signals with register values
- go to S_WB (where you store alu_o into register + default-increment pc)
if LOAD/STORE
- if load/store -> go to S_MEM
if JAL 
- if jal -> go to S_WB (where you write to rd + increment PC)
if JALR
- if jalr -> go to S_WB (where you write to rd, increment PC with register value)
*/
/**
FUNCTIONALITY
- contains all control submodules
- Supposed to keep track of the current cpu state and used the submodule returns accordingly
	- Drives the ALU (register value outputs + alu write enable + alu_read)
	- Initializes / Checks whether the instruction fetch is done
	- Initializes / Checks whether the memory load / store is done
INPUTS:
- instruction
*/

/**
INSIDE THE CORE CONTROL
- Make sure to select a different the ALU-immediate if we're dealing with an ALU instruction, and output that immediate
- Make sure to determine whether the instruction is an ALU instruction
- Add a jump-handler instruction
- Check whether a branch or jump is being taken, and increment the program counter accordingly
- Generate the required core_mem signals depending on the core_cmem control signals and the machine state

-> OR maybe just put all this control logic INSIDE the core instead of in a package where a million signals go in and out?
-> It will lead to a LOT of signals in one though.
*/

/**
// !NOTE:
- It makes more sense to have the state machine centralized and propagate signals from the state machine
	- IF: you can set your modules as separate states
	- BECAUSE: then you don't propagate the states, you just drive all your pipelin-control signals from your central state machine inside your control circuitry.
// !NOTE:
- Decode the read / write indices combinatorially, and latch them.
- If you need for example the write signal for a certain instruction what is done is
	- It is usually carried along hte pipeline through the states in a register.
*/

/**
//! NOTE:
- Normally all pipelining registers are kept centralized
	- So they can be easily passed along through pipelined stages if necessary
	- Make sure to do that later once you've actually implemented the FSM with latches in ALU / BRANCHING / MEMORY modules
- NORMALLY all modules are in fact purely combinatorial
	- So make sure to bring all latched registers inside the instruction decoding outside of it
	- Keep them somewhere central
- For now latch the registers on the outside
	- Keep the complex pipelining-register logic for a later stage, make sure your FSM works first
*/
/**
//! NOTE:
- Signals set in an always block should always be set as registers
HOWEVER: they won't be inferred as registers 
- IF assigned in every posible branch of the combinatorial process.
- ELSE latches might be inferred.
*/

/**
// ? Can we directly jump from the IFETCH stage to the WD stage for JALR / JAL INSTRUCTIONS?
*/
