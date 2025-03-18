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

module core_control (
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

    output reg [31:0] idex_reg_rdata1,
    output reg [31:0] idex_reg_rdata2,

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

    // *** CONTROL SIGNALS
    // Instruction fetch should always happen unless stall happens.
    // And make the imem finish to avoid occupying the bus continuously in case of a memory fetch.
    // PC Should be updated every clock-cycle if not in stall-mode.
    output reg C_PC_UPDATE,
    output reg  memwb_c_reg_awvalid,
    output  C_ISLOAD_SS,
    output  C_ISSTORE_SS,
    output reg  idex_c_isalu,

    // *** INSTRUCTION / DATA MEMORY HCU SIGNALS
    input HCU_IMEM_BUSY,
    input HCU_DMEM_BUSY,
    input HCU_IMEM_DONE
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
  wire hcu_idex_write, hcu_exmem_write, hcu_idex_flush, hcu_exmem_flush, hcu_memwb_write;

  // ***********************************************************************
  // PIPELINE REGISTERS
  // ***********************************************************************
  // *** INSTRUCTION ***
  reg [31:0] ifid_instruction;

  // *** PC ***
  reg [31:0] ifid_pc, idex_pc, exmem_pc, memwb_pc;

  // *** REGISTER SIGNALS ***
  reg [31:0] exmem_reg_rdata1; // (idex_reg_rdata1)
  reg [31:0] exmem_reg_rdata2; // (idex_reg_rdata2)
  reg [4:0] idex_reg_awaddr, exmem_reg_awaddr;
  reg idex_c_reg_awvalid, exmem_c_reg_awvalid; // (o) idex_c_reg_awvalid

  // *** IMMEDIATES ***
  reg [31:0] exmem_imm, memwb_imm; // (o) idex_imm

  // *** ALU ***
  reg [31:0] exmem_alu_o, memwb_alu_o;
  reg exmem_c_isalu, memwb_c_isalu; // (o) idex_c_isalu

  // *** MEM ***
  reg idex_c_isload, exmem_c_isload, memwb_c_isload; //
  reg idex_c_isstore, exmem_c_isstore; //

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
      .INSTRUCTION(ifid_instruction),
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
      .STRB(STRB),
      .BUSY(HCU_DMEM_BUSY),
      .EXMEM_C_ISSTORE(exmem_c_isstore),
      .EXMEM_C_ISLOAD(exmem_c_isload),
      .ISSTORE_SS(C_ISSTORE_SS),
      .ISLOAD_SS(C_ISLOAD_SS)
  );

  // Happened isjal -> isjalr
  core_cpc_update cpc_update_inst (
    .IMM(idex_imm),
    .REG_RDATA1(idex_reg_rdata1),
    .C_TAKE_BRANCH(c_take_branch),
    .ISJAL(idex_c_isjal),
    .ISJALR(idex_c_isjalr),
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
    .IDEX_REG_AWADDR(idex_reg_awaddr),
    .IDEX_REG_AWVALID(idex_c_reg_awvalid),
    .EXMEM_REG_AWADDR(exmem_reg_awaddr),
    .EXMEM_REG_AWVALID(exmem_c_reg_awvalid),
    .MEMWB_REG_AWADDR(memwb_reg_awaddr),
    .MEMWB_REG_AWVALID(memwb_c_reg_awvalid),
    .C_TAKE_BRANCH(c_take_branch),
    .ISJAL(idex_c_isjal),
    .ISJALR(idex_c_isjalr),
    .HCU_DMEM_BUSY(HCU_DMEM_BUSY),
    .HCU_IMEM_BUSY(HCU_IMEM_BUSY),
    .HCU_IMEM_DONE(HCU_IMEM_DONE),
    .HCU_IFID_WRITE(hcu_ifid_write),
    .HCU_IFID_FLUSH(hcu_ifid_flush),
    .HCU_IDEX_WRITE(hcu_idex_write),
    .HCU_IDEX_FLUSH(hcu_idex_flush),
    .HCU_EXMEM_WRITE(hcu_exmem_write),
    .HCU_EXMEM_FLUSH(hcu_exmem_flush),
    .HCU_MEMWB_WRITE(hcu_memwb_write),
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

  // IFID

  always @(posedge CLK)
  begin
    if (!NRST | hcu_ifid_flush)
    begin
      ifid_pc <= 32'hA;
      ifid_instruction <= 32'h13;
    end
    else
    begin
      if (hcu_ifid_write)
      begin
        ifid_pc <= PC;
        ifid_instruction <= INSTRUCTION;
      end
      else;
    end
  end
  // IDEX
  always @(posedge CLK)
  begin
    if (!NRST | hcu_idex_flush)
    begin
        // IF R-ALU or I-ALU or STORE or LOAD
      idex_reg_rdata1 <= 32'b0;
      idex_reg_rdata2 <= 32'b0;
      idex_reg_awaddr <= 5'b0;
      idex_c_reg_awvalid <= 1'b0;

      // IF BRANCHING
      idex_imm <= 32'hAAAA;
      idex_c_isimm <= 1'b0;

      // CONTROL SIGNALS
      idex_c_isbranch <= 1'b0;
      idex_c_isalu <= 1'b0;
      idex_c_isjalr <= 1'b0;
      idex_c_isjal <= 1'b0;
      idex_c_islui <= 1'b0;
      idex_c_isauipc <= 1'b0;
      idex_c_isload <= 1'b0;

      idex_c_isload <= 1'b0;
      idex_c_isstore <= 1'b0;

      // PROGRAM COUNTER
      idex_pc <= 32'hAAAA;
    end
    else if (hcu_idex_write)
    begin
      // IF R-ALU or I-ALU or STORE or LOAD
      idex_reg_rdata1 <= REG_RDATA1;
      idex_reg_rdata2 <= REG_RDATA2;
      idex_reg_awaddr <= reg_awaddr;
      idex_c_reg_awvalid <= c_reg_awvalid;

      // IF BRANCHING
      idex_imm <= imm_dec;
      idex_c_isimm <= c_isimm;

      // CONTROL SIGNALS
      idex_c_isbranch <= c_isbranch;
      idex_c_isalu <= c_isalu;
      idex_c_isjalr <= c_isjalr;
      idex_c_isjal <= c_isjal;
      idex_c_islui <= c_islui;
      idex_c_isauipc <= c_isauipc;
      idex_c_isload <= c_isload;
      idex_c_isstore <= c_isstore;

      // PROGRAM COUNTER
      idex_pc <= ifid_pc;
  end
  else; // STALL
end

always @(posedge CLK)
begin
    if (!NRST | hcu_exmem_flush)
    begin
      exmem_reg_rdata1 <= 32'b0;
      exmem_reg_rdata2 <= 32'b0;
      exmem_reg_awaddr <= 5'b0;
      exmem_c_reg_awvalid <= 1'b0;

      // Control signals
      exmem_c_isload <= 1'b0;
      exmem_c_isstore <= 1'b0;
      exmem_c_isalu <= 1'b0;
      exmem_c_isauipc <= 1'b0;
      exmem_c_islui <= 1'b0;
      exmem_c_isjal <= 1'b0;
      exmem_c_isjalr <= 1'b0;

      // Other
      exmem_c_take_branch <= 1'b0;
      exmem_alu_o <= 32'hBBBB;
      exmem_pc <= 32'hBBBB;
      exmem_imm <= 32'hBBBB;
    end
    else if (hcu_exmem_write)
      begin
      //! EXMEM
      // if store / load instruction
      exmem_reg_rdata1 <= idex_reg_rdata1;
      exmem_reg_rdata2 <= idex_reg_rdata2;
      exmem_reg_awaddr <= idex_reg_awaddr;
      exmem_c_reg_awvalid <= idex_c_reg_awvalid;

      // IF branching store / load
      exmem_c_isload <= idex_c_isload;
      exmem_c_isstore <= idex_c_isstore;
      exmem_c_isalu <= idex_c_isalu;
      exmem_c_isauipc <= idex_c_isauipc;
      exmem_c_islui <= idex_c_islui;
      exmem_c_isjal <= idex_c_isjal;
      exmem_c_isjalr <= idex_c_isjalr;


      // Other
      exmem_c_take_branch <= c_take_branch;
      exmem_alu_o <= ALU_O;
      exmem_pc <= idex_pc;
      exmem_imm <= idex_imm;
    end
    else;
end

always @(posedge CLK)
begin
  if (!NRST)
  begin
    // if store / load instruction
    memwb_reg_awaddr <= 1'b0;
    memwb_c_reg_awvalid <= 1'b0;

    // IF branching store / load
    memwb_c_isload <= 1'b0;
    memwb_c_isalu <= 1'b0;
    memwb_c_isauipc <= 1'b0;
    memwb_c_islui <= 1'b0;
    memwb_c_isjal <= 1'b0;
    memwb_c_isjalr <= 1'b0;

    // Other
    memwb_imm <= 32'hDDDD;
    memwb_pc <= 32'hDDDD;
    memwb_alu_o <= 32'b0;
  end
  else if (hcu_memwb_write) // MEMORY HAZARD
  begin
    // if store / load instruction
    memwb_reg_awaddr <= exmem_reg_awaddr;
    memwb_c_reg_awvalid <= exmem_c_reg_awvalid;

      // IF branching store / load
    memwb_c_isload <= exmem_c_isload;
    memwb_c_isalu <= exmem_c_isalu;
    memwb_c_isauipc <= exmem_c_isauipc;
    memwb_c_islui <= exmem_c_islui;
    memwb_c_isjal <= exmem_c_isjal;
    memwb_c_isjalr <= exmem_c_isjalr;

    // Other
    memwb_imm <= exmem_imm;
    memwb_pc <= exmem_pc;
    memwb_alu_o <= exmem_alu_o;
  end
  else;
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