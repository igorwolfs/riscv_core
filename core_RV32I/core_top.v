`timescale 1ns/10ps

`include "config.vh"
/**


The program counter needs to be updated on every clock cycle.
- PC+4 (normally)
- PC+other_number (depending on )
*/


module core_top #(
    parameter AXI_AWIDTH = 4,
    parameter AXI_DWIDTH = 32)
  (
    // SYSTEM
    input  CLK, NRST,

    // *** DATA MEMORY / PERIPHERAL INTERFACE ***
    // Write Address Bus
    output [AXI_AWIDTH-1:0]       HOST_AXI_AWADDR,
    output                        HOST_AXI_AWVALID,
    input                         HOST_AXI_AWREADY,
    // Write Data Bus
    output [AXI_DWIDTH-1:0]       HOST_AXI_WDATA,
    output [((AXI_DWIDTH/8))-1:0] HOST_AXI_WSTRB,
    output                        HOST_AXI_WVALID,
    input                         HOST_AXI_WREADY,
    // Response Bus
    input  [1:0]                  HOST_AXI_BRESP,
    input                         HOST_AXI_BVALID,
    output                        HOST_AXI_BREADY,
    // Address Read Bus
    output [AXI_AWIDTH-1:0]       HOST_AXI_ARADDR,
    output                        HOST_AXI_ARVALID,
    input                         HOST_AXI_ARREADY,
    // Data Read Bus
    input  [AXI_DWIDTH-1:0]       HOST_AXI_RDATA,
    input  [1:0]                  HOST_AXI_RRESP,
    input                         HOST_AXI_RVALID,
    output                        HOST_AXI_RREADY,

    // *** INSTRUCTION MEMORY INTERFACE ***
    // Read Address Bus
    output [AXI_AWIDTH-1:0]       IMEM_AXI_ARADDR,
    output                        IMEM_AXI_ARVALID,
    input                         IMEM_AXI_ARREADY,
    // Read Data Bus
    input  [AXI_DWIDTH-1:0]       IMEM_AXI_RDATA,
    input  [1:0]                  IMEM_AXI_RRESP,
    input                         IMEM_AXI_RVALID,
    output                        IMEM_AXI_RREADY
  );

  // general
  wire [31:0] imm;

  // ALU COMMANDS
  wire c_alu, c_alu_regwrite;
  wire [31:0] alu_i1, alu_i2, alu_o;
  wire [9:0] alu_cid;

  // REGISTER READ / WRITE
  wire reg_awvalid;
  wire [4:0] reg_awaddr, reg_araddr1, reg_araddr2;
  wire [31:0] reg_wdata, reg_rdata1, reg_rdata2;

  // INSTRUCTION FETCH
  wire c_instr_fetch;     // On high -> Instruction fetch 
  wire [31:0] instruction;
  wire c_pc_update;
  wire [3:0] c_wb_code;       // On high -> PC update
  wire [31:0] jump_imm;  // PC update number
  wire [31:0] pc;

  // DATA MEMORY
  wire c_doload, c_doloadbs, c_doloadhws;
  wire c_dostore;
  wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
  wire [3:0] dmem_strb;

  // ************ UNITS *****************

  // *** ALU UNIT ***
  assign alu_i1 = reg_rdata1;
  assign alu_i2 = is_imm ? imm : reg_rdata2;
  core_alu #() alu_t (.CLK(CLK), .C_ALU(c_alu), .OPCODE_ALU(opcode_alu), .ALU_I1(alu_i1),
  .ALU_I2(alu_i2), .ALU_O(alu_o));

  // *** CONTROL UNIT ***
  core_control core_control_inst (
    // CLK / NRST
    .CLK(CLK), .NRST(NRST),
    .INSTRUCTION(instruction),

    // PC operations
    .PC(pc),
    .C_INSTR_FETCH(c_instr_fetch),
    .C_PC_UPDATE(c_pc_update), .C_ISBRANCH(c_isbranch),
    .C_WB_CODE(c_wb_code),

    // REGISTER OPERATIONS
    .C_ALU_REGWRITE(c_alu_regwrite), .C_REG_AWVALID(reg_awvalid),
    .REG_ARADDR1(reg_araddr1), .REG_ARADDR2(reg_araddr2),
    .REG_AWADDR(reg_awaddr), .REG_RDATA1(reg_rdata1),
    .REG_RDATA2(reg_rdata2),
    .IMM(imm),
    .C_ALU(c_alu), .OPCODE_ALU(opcode_alu),
    .IS_IMM(is_imm),

    // MEMORY OPERATIONS (LOAD / STORE)
    .DMEM_ARADDR(dmem_addr),
    .C_DOLOAD(c_doload), .ISLOADBS(isloadbs),
    .ISLOADHWS(isloadhws), .C_DOSTORE(c_dostore),
    .STRB(dmem_strb),

    // AXI SIGNALS FOR CONTROL
    // > IMEM (READ ONLY)
    .IMEM_AXI_RVALID(IMEM_AXI_RVALID), .IMEM_AXI_RREADY(IMEM_AXI_RREADY),
    // > DMEM (LOAD / STORE)
    .HOST_AXI_RVALID(HOST_AXI_RVALID), .HOST_AXI_RREADY(HOST_AXI_RREADY),
    .HOST_AXI_BVALID(HOST_AXI_BVALID), .HOST_AXI_BREADY(HOST_AXI_BREADY)
);


  // *** INSTRUCTION FETCH (AXI MASTER) ***
    wire [31:0] pc_next;
    always @(*)
    begin
      pc_next = pc+4;
      case (c_wb_code)
        `WB_CODE_JAL, `WB_CODE_BRANCH:
          pc_next = pc+imm;
        `WB_CODE_JALR:
          pc_next = reg_rdata1+imm;
        default:
          pc_next = pc+4;
      endcase
    end

    core_ifetch #(
        .AXI_AWIDTH(AXI_AWIDTH),
        .AXI_DWIDTH(AXI_DWIDTH)
    ) core_ifetch_inst (
        .CLK(CLK),
        .NRST(NRST),
        .AXI_ARADDR(IMEM_AXI_ARADDR), .AXI_ARVALID(IMEM_AXI_ARVALID),
        .AXI_ARREADY(IMEM_AXI_ARREADY), .AXI_RDATA(IMEM_AXI_RDATA),
        .AXI_RRESP(IMEM_AXI_RRESP), .AXI_RVALID(IMEM_AXI_RVALID),
        .AXI_RREADY(IMEM_AXI_RREADY), // Goes high when fetch succeeded

        .C_INSTR_FETCH(c_instr_fetch),
        .INSTRUCTION(instruction),

        .C_PC_UPDATE(c_pc_update),
        .PC_NEXT(pc_next),
        .PC(pc)
    );

  // *** MEMORY CONTROLLER (AXI MASTER) ***

    core_mem #(
        .AXI_AWIDTH(AXI_AWIDTH),
        .AXI_DWIDTH(AXI_DWIDTH)
    ) core_imem_inst (
        .CLK(CLK),
        .NRST(NRST),

        .AXI_AWADDR(HOST_AXI_AWADDR), .AXI_AWVALID(HOST_AXI_AWVALID),
        .AXI_AWREADY(HOST_AXI_AWREADY), .AXI_WDATA(HOST_AXI_WDATA),
        
        .AXI_WSTRB(HOST_AXI_WSTRB), .AXI_WVALID(HOST_AXI_WVALID),
        .AXI_WREADY(HOST_AXI_WREADY), .AXI_BRESP(HOST_AXI_BRESP),
        
        .AXI_BVALID(HOST_AXI_BVALID), .AXI_BREADY(HOST_AXI_BREADY),
        .AXI_ARADDR(HOST_AXI_ARADDR), .AXI_ARVALID(HOST_AXI_ARVALID),
        
        .AXI_ARREADY(HOST_AXI_ARREADY), .AXI_RDATA(HOST_AXI_RDATA),
        .AXI_RRESP(HOST_AXI_RRESP), .AXI_RVALID(HOST_AXI_RVALID),
        .AXI_RREADY(HOST_AXI_RREADY),

        .C_DOLOAD(c_doload), .DOLOADBS(doloadbs),
        .DOLOADHWS(doloadhws), .C_DOSTORE(c_dostore),
        
        .ADDR(dmem_addr), .WDATA(reg_rdata2),
        .RDATA(dmem_rdata), .STRB(dmem_strb)
    );

  // *** REGISTERS ***
  // USE the c_wb_code to determine the reg_wdata in an always @-loop
  always @(*)
  begin
    reg_wdata = 32'hDEADBEEF;
    case (c_wb_code)
      `WB_CODE_ALU:
        reg_wdata = alu_o;
      `WB_CODE_JALR, WB_CODE_JAL:
        reg_wdata = pc+4;
      `WB_CODE_LUI:
        reg_wdata = imm;
      `WB_CODE_AUIPC:
        reg_wdata = pc+imm;
      `WB_CODE_LOAD:
        reg_wdata = dmem_rdata; //! PROBABLY WRONG BYTE ORDERING HERE
      default:
        reg_wdata = 32'hDEADBEEF;
    endcase
  end

  core_registers #() registers_t (.CLK(CLK), .NRST(NRST), // SYS
  .AWVALID(reg_awvalid), .WDATA(reg_wdata), .AWADDR(reg_awaddr), // WRITE
  .ARADDR1(reg_araddr1), .ARADDR2(reg_araddr2), .RDATA1(reg_rdata1), .RDATA2(reg_rdata2)); // READ

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
  - 

*/