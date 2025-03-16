`timescale 1ns / 10ps

`include "define.vh"

module core_top #(
    parameter AXI_AWIDTH = 32,
    parameter AXI_DWIDTH = 32
) (
    // SYSTEM
    input CLK, NRST,

    // *** DATA MEMORY / PERIPHERAL INTERFACE ***
    // Write Address Bus
    output [      AXI_AWIDTH-1:0] HOST_AXI_AWADDR,
    output                        HOST_AXI_AWVALID,
    input                         HOST_AXI_AWREADY,
    // Write Data Bus
    output [      AXI_DWIDTH-1:0] HOST_AXI_WDATA,
    output [((AXI_DWIDTH/8))-1:0] HOST_AXI_WSTRB,
    output                        HOST_AXI_WVALID,
    input                         HOST_AXI_WREADY,
    // Response Bus
    input  [                 1:0] HOST_AXI_BRESP,
    input                         HOST_AXI_BVALID,
    output                        HOST_AXI_BREADY,
    // Address Read Bus
    output [      AXI_AWIDTH-1:0] HOST_AXI_ARADDR,
    output                        HOST_AXI_ARVALID,
    input                         HOST_AXI_ARREADY,
    // Data Read Bus
    input  [      AXI_DWIDTH-1:0] HOST_AXI_RDATA,
    input  [                 1:0] HOST_AXI_RRESP,
    input                         HOST_AXI_RVALID,
    output                        HOST_AXI_RREADY,

    // *** INSTRUCTION MEMORY INTERFACE ***
    // Read Address Bus
    output [AXI_AWIDTH-1:0] IMEM_AXI_ARADDR,
    output                  IMEM_AXI_ARVALID,
    input                   IMEM_AXI_ARREADY,
    // Read Data Bus
    input  [AXI_DWIDTH-1:0] IMEM_AXI_RDATA,
    input  [           1:0] IMEM_AXI_RRESP,
    input                   IMEM_AXI_RVALID,
    output                  IMEM_AXI_RREADY
);

  // general
  wire [31:0] idex_imm;
  wire isimm;

  // ALU COMMANDS
  wire c_alu;
  wire [31:0] alu_i1, alu_i2, alu_o;
  wire [3:0] opcode_alu;

  // REGISTER READ / WRITE
  wire reg_awvalid;
  wire [4:0] reg_awaddr, reg_araddr1, reg_araddr2;
  wire [31:0] reg_rdata1, reg_rdata2, reg_wdata;

  // INSTRUCTION FETCH
  wire [31:0] instruction;
  wire        c_pc_write, hcu_imem_busy;
  wire [31:0] jump_imm;  // PC update number
  wire [31:0] pc, pc_next;

  // DATA MEMORY
  wire c_isstore, c_isload, isloadbs, isloadhws, hcu_dmem_busy;
  wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
  wire [3:0] dmem_strb;

  wire hcu_mem_busy, hcu_imem_done;

  assign hcu_mem_busy = hcu_dmem_busy | hcu_imem_busy;
  // ************ UNITS *****************

  // *** ALU UNIT ***
  assign alu_i1 = reg_rdata1;
  assign alu_i2 = isimm ? idex_imm : reg_rdata2;

  core_alu #() alu_t (
      .CLK(CLK),
      .C_ALU(c_alu),
      .OPCODE_ALU(opcode_alu),
      .ALU_I1(alu_i1),
      .ALU_I2(alu_i2),
      .ALU_O(alu_o)
  );

  // *** CONTROL UNIT ***
  core_control #() core_control_inst (
      // CLK / NRST
      .CLK(CLK),
      .NRST(NRST),
      .INSTRUCTION(instruction),

      // PC Operations
      .PC(pc),
      .PC_NEXT(pc_next),
      // REGISTER OPERATIONS
      .memwb_c_reg_awvalid(reg_awvalid),
      .REG_ARADDR1(reg_araddr1),
      .REG_ARADDR2(reg_araddr2),
      .memwb_reg_awaddr(reg_awaddr),
      .REG_WDATA(reg_wdata),
      .REG_RDATA1(reg_rdata1),
      .REG_RDATA2(reg_rdata2),
      .idex_imm(idex_imm),
      .ALU_O(alu_o),
      .idex_c_isalu(c_alu),
      .OPCODE_ALU(opcode_alu),
      .idex_c_isimm(isimm),

      // MEMORY OPERATIONS (LOAD / STORE)
      .DMEM_ADDR(dmem_addr),
      .DMEM_RDATA(dmem_rdata),
      .C_ISLOAD_SS(c_isload),
      .ISLOADBS(isloadbs),
      .ISLOADHWS(isloadhws),
      .C_ISSTORE_SS(c_isstore),
      .STRB(dmem_strb),
      .HCU_PC_WRITE(c_pc_write),
      .HCU_MEM_BUSY(hcu_mem_busy),
      .HCU_IMEM_DONE(hcu_imem_done)
  );


  // *** INSTRUCTION FETCH (AXI MASTER) ***
  core_ifetch #(
      .AXI_AWIDTH(AXI_AWIDTH),
      .AXI_DWIDTH(AXI_DWIDTH)
  ) core_ifetch_inst (
      .CLK(CLK),
      .NRST(NRST),
      .AXI_ARADDR(IMEM_AXI_ARADDR),
      .AXI_ARVALID(IMEM_AXI_ARVALID),
      .AXI_ARREADY(IMEM_AXI_ARREADY),
      .AXI_RDATA(IMEM_AXI_RDATA),
      .AXI_RRESP(IMEM_AXI_RRESP),
      .AXI_RVALID(IMEM_AXI_RVALID),
      .AXI_RREADY(IMEM_AXI_RREADY),  // Goes high when fetch succeeded
      .PC_WRITE(c_pc_write),
      .INSTRUCTION(instruction),
      .BUSY(hcu_imem_busy),
      .DONE(hcu_imem_done),
      .PC_NEXT(pc_next),
      .PC(pc)
  );

  // *** MEMORY CONTROLLER (AXI MASTER) ***
  core_mem #(
      .AXI_AWIDTH(AXI_AWIDTH),
      .AXI_DWIDTH(AXI_DWIDTH)
  ) core_mem_inst (
      .CLK (CLK),
      .NRST(NRST),

      .AXI_AWADDR (HOST_AXI_AWADDR),
      .AXI_AWVALID(HOST_AXI_AWVALID),
      .AXI_AWREADY(HOST_AXI_AWREADY),
      .AXI_WDATA  (HOST_AXI_WDATA),

      .AXI_WSTRB (HOST_AXI_WSTRB),
      .AXI_WVALID(HOST_AXI_WVALID),
      .AXI_WREADY(HOST_AXI_WREADY),
      .AXI_BRESP (HOST_AXI_BRESP),

      .AXI_BVALID (HOST_AXI_BVALID),
      .AXI_BREADY (HOST_AXI_BREADY),
      .AXI_ARADDR (HOST_AXI_ARADDR),
      .AXI_ARVALID(HOST_AXI_ARVALID),

      .AXI_ARREADY(HOST_AXI_ARREADY),
      .AXI_RDATA  (HOST_AXI_RDATA),
      .AXI_RRESP  (HOST_AXI_RRESP),
      .AXI_RVALID (HOST_AXI_RVALID),
      .AXI_RREADY (HOST_AXI_RREADY),

      .BUSY(hcu_dmem_busy),

      .ISLOADBS (isloadbs),
      .ISLOADHWS(isloadhws),

      .C_ISSTORE_SS(c_isstore),
      .C_ISLOAD_SS(c_isload),

      .ADDR (dmem_addr),
      .WDATA(reg_rdata2),
      .RDATA(dmem_rdata),
      .STRB (dmem_strb)
  );


  // *** REGISTERS ***
  core_registers #() registers_t (
      .CLK(CLK),
      .NRST(NRST),            // SYS
      .AWVALID(reg_awvalid),
      .WDATA(reg_wdata),
      .AWADDR(reg_awaddr),    // WRITE
      .ARADDR1(reg_araddr1),
      .ARADDR2(reg_araddr2),
      .RDATA1(reg_rdata1),    // READ
      .RDATA2(reg_rdata2)
  );

endmodule

/**
REFACTORING:
1. INSTRUCTION FETCH STATE: 
  - Fetch instruction (block AXI here if necessary)
  - Check if instruction is
      - branch -> Increment PC depending on ALU outcome
      - jal(r) -> Increment PC depending on imm / rs1+imm
      - regular instruction -> increment PC by 4
  @ARG:
    - AXI IMEM bus
    - isbranch
    - isjal(r)
  @OUT:
2. INSTRUCTION DECODE STATE:
    - Take 32-bit instruction, slice into (opcode, rs1, rs2, funct3, funct7) + classification
    - Get immediates -> output
    - register read addresses
3. CONTROL:
    - branch_control -> takes relevant values and checks whether branch is taken
    - alu_control -> decodes funct3 / funct7 to produce alu operation signals
    - mem_control -> load / store / wordsize
4. EXEC
  - MEMORY / AXI INTERFACE:
  - ALU
  - REGISTER FILE

*/
