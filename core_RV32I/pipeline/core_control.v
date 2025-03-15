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
    output [31:0] PC_NEXT,

    // *** REGISTER SIGNALS
    output [ 4:0] REG_ARADDR1,  // Which read register 1 to use
    output [ 4:0] REG_ARADDR2,  // Which read register 2 to use
    output reg [ 4:0] memwb_reg_awaddr,   // Which register to write to
    output [31:0] REG_WDATA,
    input  [31:0] REG_RDATA1,
    input  [31:0] REG_RDATA2,

    // *** ALU SIGNALS
    output [3:0]        OPCODE_ALU,
    input  [31:0]       ALU_O,
    output reg [31:0]   idex_imm,
    output reg          idex_c_isimm,   // Shows whether its an immediate instruction or not => Used by alu when selecting REG2 vs immediate

    // *** MEMORY SIGNALS
    output [31:0] DMEM_ADDR,  // Determines load / store address
    input [31:0] DMEM_RDATA,
    output ISLOADBS,
    output ISLOADHWS,
    output [3:0] STRB,

    output HCU_PC_WRITE,

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
    output reg C_PC_UPDATE,
    output reg  memwb_c_reg_awvalid,
    output reg  exmem_c_isload,
    output reg  exmem_c_isstore,
    output reg  idex_c_isalu
);

  // ***********************************************************************
  // SIGNAL DEFINES
  // ***********************************************************************

  // *** IDECODE-STAGE SIGNALS ***
  // General
  wire [2:0] funct3;
  wire [6:0] funct7;
  wire [31:0] imm_dec;
  wire c_isimm;
  // Registers
  wire c_reg1_memread, c_reg2_memread, c_reg_awvalid;
  wire [3:0] reg_awaddr;
  // Commands
  wire c_isbranch, c_isalu, c_isstore, c_isload;
  wire c_isjal, c_isjalr, c_isauipc, c_islui;

  // *** HCU WIRES ***
  wire hcu_idex_enable, hcu_exmem_enable, hcu_idex_flush, hcu_exmem_flush;

  // Signal indications for memory operations (imem and cmem)
  wire c_imem_done, c_mem_done;
  
  assign c_imem_done = IMEM_AXI_RVALID & IMEM_AXI_ARREADY;
  assign c_mem_done = ((HOST_AXI_RREADY & HOST_AXI_RVALID) | (HOST_AXI_BVALID & HOST_AXI_BREADY));


  // ***********************************************************************
  // PIPELINE REGISTERS
  // ***********************************************************************

  // *** PC ***
  reg [31:0] idex_pc, exmem_pc, memwb_pc;

  // *** REGISTER SIGNALS ***
  reg [31:0] idex_reg_rdata1, exmem_reg_rdata1;
  reg [31:0] idex_reg_rdata2, exmem_reg_rdata2;
  reg [4:0] idex_reg_awaddr, exmem_reg_awaddr;
  reg idex_c_reg_awvalid, exmem_c_reg_awvalid; // (o) idex_c_reg_awvalid

  // *** IMMEDIATES ***
  reg [31:0] exmem_imm, memwb_imm; // (o) idex_imm

  // *** ALU ***
  reg [31:0] exmem_alu_o, memwb_alu_o;
  reg exmem_c_isalu, memwb_c_isalu; // (o) idex_c_isalu

  // *** MEM ***
  reg idex_c_isload, memwb_c_isload;// (o) exmem_c_isload
  reg idex_c_isstore; // (o) exmem_c_isstore

  // *** BRANCHING / JUMPS ***
  reg idex_c_isauipc, exmem_c_isauipc, memwb_c_isauipc;
  reg idex_c_islui, exmem_c_islui, memwb_c_islui;
  reg idex_c_isjal, exmem_c_isjal, memwb_c_isjal;
  reg idex_c_isjalr, exmem_c_isjalr, memwb_c_isjalr;
  reg idex_c_isbranch;
  reg exmem_c_take_branch;

  // ***********************************************************************
  // MODULES
  // ***********************************************************************

  core_idecode core_idecode_inst (
      .CLK(CLK),
      .NRST(NRST),
      .INSTRUCTION(INSTRUCTION),
      .FUNCT3(funct3),
      .FUNCT7(funct7),
      .IMM_DEC(imm_dec),
      .C_ISIMM(c_isimm),
      .C_ISALU(c_isalu),
      .C_ISBRANCH(c_isbranch),
      .C_ISLOAD(c_isload),
      .C_ISSTORE(c_isstore),
      .C_ISJAL(c_isjal),
      .C_ISJALR(c_isjalr),
      .C_ISLUI(c_islui),
      .C_ISAUIPC(c_isauipc),
      .C_REG_AWVALID(c_reg_awvalid),
      .C_REG1_MEMREAD(c_reg1_memread),
      .C_REG2_MEMREAD(c_reg2_memread),
      .REG_ARADDR1(REG_ARADDR1), // Do not save as intermediate -> address only needed in next stage
      .REG_ARADDR2(REG_ARADDR2),
      .REG_AWADDR(reg_awaddr)
  );

  core_calu core_calu_inst (
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
      .C_ISBRANCH(idex_c_isbranch),
      .FUNCT3(funct3),
      .REG_RDATA1(idex_reg_rdata1),
      .REG_RDATA2(idex_reg_rdata2),
      .TAKE_BRANCH(c_take_branch)
  );

  core_cmem core_cmem_inst (
      .CLK(CLK),
      .NRST(NRST),
      .ISLOAD(idex_c_isload),
      .ISSTORE(idex_c_isstore),
      .PC(PC),
      .IMM(idex_imm),
      .REG_RDATA1(idex_reg_rdata1),
      .FUNCT3(funct3),
      .DMEM_ADDR(DMEM_ADDR),
      .ISLOADBS(ISLOADBS),
      .ISLOADHWS(ISLOADHWS),
      .STRB(STRB)
  );

  // Happened isjal -> isjalr
  core_cpc_update cpc_update_inst (
    .IMM(idex_imm),
    .REG_RDATA1(REG_RDATA1),
    .C_TAKE_BRANCH(c_take_branch),
    .ISJAL(c_isjal),
    .ISJALR(c_isjalr),
    .PC(PC),
    .IDEX_PC(idex_pc),
    .PC_NEXT(PC_NEXT)
  );

  core_wb core_wb_inst (
    .MEMWB_ALU_O(memwb_alu_o),
    .MEMWB_PC(memwb_pc),
    .MEMWB_IMM(memwb_imm),
    .DMEM_RDATA(DMEM_RDATA),
    .MEMWB_ISALU(memwb_c_isalu),
    .MEMWB_ISJALR(memwb_c_isjalr),
    .MEMWB_ISJAL(memwb_c_isjal),
    .MEMWB_ISLUI(memwb_c_islui),
    .MEMWB_ISAUIPC(memwb_c_isauipc),
    .MEMWB_ISLOAD(memwb_c_isload),
    .REG_WDATA(REG_WDATA)
  );


  core_hcu core_hcu_inst (
    .REG_ARADDR1(REG_ARADDR1),
    .REG_ARADDR2(REG_ARADDR2),
    .C_REG1_MEMREAD(c_reg1_memread),
    .C_REG2_MEMREAD(c_reg2_memread),
    .EXMEM_REG_AWADDR(exmem_reg_awaddr),
    .MEMWB_REG_AWADDR(memwb_reg_awaddr),
    .C_TAKE_BRANCH(c_take_branch),
    .HCU_IDEX_ENABLE(hcu_idex_enable),
    .HCU_IDEX_FLUSH(hcu_idex_flush),
    .HCU_EXMEM_ENABLE(hcu_exmem_enable),
    .HCU_EXMEM_FLUSH(hcu_exmem_flush),
    .HCU_PC_WRITE(HCU_PC_WRITE)
  );

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

  // *** SYNCHRONOUS LOGIC ***
  // IDEX
  always @(posedge CLK)
  begin
    if (hcu_idex_enable) // MAKE SURE
    begin
      //! IDEX
      // IF R-ALU or I-ALU or STORE or LOAD
      idex_reg_rdata1 <= REG_RDATA1;
      idex_reg_rdata2 <= REG_RDATA2;
      idex_reg_awaddr <= reg_awaddr;

      // IF BRANCHING
      idex_imm <= imm_dec;
      idex_c_isimm <= c_isimm;

      // CONTROL SIGNALS
      idex_c_isbranch <= c_isbranch;
      idex_c_isalu <= c_isalu;
      idex_c_isload <= c_isload;
      idex_c_isstore <= c_isstore;
      idex_c_reg_awvalid <= c_reg_awvalid;

      // PROGRAM COUNTER
      idex_pc <= PC;
    end
    else if (hcu_idex_flush)
      begin
        idex_reg_rdata1 <= 0;
        idex_reg_rdata2 <= 0;
        idex_reg_awaddr <= 0;
        idex_imm <= 0;
        idex_c_isimm <= 1;
        idex_c_isbranch <= 0;
        idex_c_isalu <= 0;
        idex_c_isload <= 0;
        idex_c_isstore <= 0;
        idex_c_reg_awvalid <= 1;
      end
    else;
    if (hcu_exmem_enable)
    begin
      //! EXMEM
      // if store / load instruction
      exmem_reg_rdata2 <= idex_reg_rdata2;
      exmem_reg_awaddr <= idex_reg_awaddr;
      // IF branching store / load
      exmem_imm <= imm_dec;
      exmem_c_take_branch <= c_take_branch;
      exmem_c_isload <= idex_c_isload;
      exmem_c_isstore <= idex_c_isstore;
      exmem_c_reg_awvalid <= idex_c_reg_awvalid;
      exmem_c_isalu <= idex_c_isalu;
      exmem_alu_o <= ALU_O;
      // PROGRAM COUNTER
      exmem_pc <= idex_pc;
    end
    else if (hcu_exmem_flush)
      begin
        exmem_reg_rdata1 <= 0;
        exmem_reg_rdata2 <= 0;
        exmem_reg_awaddr <= 0;
        exmem_imm <= 0;
        exmem_c_isload <= 0;
        exmem_c_isstore <= 0;
        exmem_c_reg_awvalid <= 1;
        exmem_c_isalu <= 0;
        exmem_alu_o <= 32'b0;
      end
    else;
    //! MEMWB
    // For any instruction except branch and store (since no write to register is done there)
    memwb_reg_awaddr <= exmem_reg_awaddr;
    // For any instruction where the PC is changed using imm
    memwb_imm <= exmem_imm;
    memwb_c_reg_awvalid <= exmem_c_reg_awvalid;
    memwb_c_isalu <= exmem_c_isalu;
    memwb_pc <= exmem_pc;
    memwb_c_isload <= exmem_c_isload;
    memwb_alu_o <= exmem_alu_o;
  end


endmodule

/**
Stalling the CPU
- Only the ifetch, idecode, exec phases need to be stalled.
The other ones need never to be stalled
- memory read / store
- write back
If the memory write takes multiple cycles, you should stall only the stages before.
The write-back may go on writing back.
So then you need to on the "stall in case of memory-read/write"-instruction
  - disable the WB
  - disable the PC increment
And in case of "stall because of data-hazard"

So in case of a pipeline data hazard, the entire pipeline can keep moving forward except for the idecode and exec stage
- You should just insert a NOP into the IDECODE stage if you see a data hazard is present
  - This way the idec->exec stage will do nothing (no memory reads)
- You should disable the PC-updating (PC+4)
In case of a pipeline control hazard
- Delay due to memory fetching:
  - The WB can simply happen
  - The signals for IDEX, EXMEM should be disabled
  - So the difference is that in a wait for MEM stage all stages should be disabled, and a PC increment and a write already occurred
  - In the 
  */

  /**
  I'm a bit confused about the difference between a stall in the case where one needs to wait for memory a memory operation to finish, and a stall in case of a data hazard (so reading a register that hasn't been written yet).
  I would use 2 different signals for this, in case of the memory-wait situation one can simply disable all signals and wait for the memory transaction to complete.
  However in case of the data hazard issue the solution seems to be to
  */