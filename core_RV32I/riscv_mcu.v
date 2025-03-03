`timescale 1ns/10ps

module riscv_mcu
    #(
        parameter INT_DMEM_SIZE = 1024 * 16,
        parameter INT_IMEM_SIZE = 1024 * 16
    )
    (
        // *** SYSTEM PINS
        input CLK, input NRST,

        // *** IO
        input RX_DSER,
        output TX_DSER

        // *** 

    );

    parameter INT_DMEM_BASE = 0;
    parameter INT_IMEM_BASE = INT_DMEM_SIZE+INT_DMEM_BASE;

    // ! ********************* SIGNALS ***************************
    // *** DATA MEMORY INTERFACE ***
    wire [31:0] dmem_araddr;
    wire [31:0] dmem_rdata;
    wire [31:0] dmem_awaddr;
    wire [31:0] dmem_wdata;
    wire        dmem_awvalid;

    // *** INSTRUCTION MEMORY INTERFACE ***
    wire [31:0] imem_araddr;
    wire [31:0] imem_rdata;

    // *** UART INTERFACE ***

    // ! ********************* ENTITIES ***************************


    // *** Internal Data Memory ***
    dmemory #(INT_DMEM_SIZE) dmemory_t (
        .CLK(CLK),
        .NRST(NRST),
        .RDATA(dmem_rdata),
        .ARADDR(dmem_araddr),
        .AWVALID(dmem_awvalid),
        .WDATA(dmem_wdata),
        .AWADDR(dmem_awaddr)
    );

    // *** Internal Instruction Memory ***
    imemory #(INT_IMEM_SIZE) imemory_t (
        .CLK(CLK),
        .ARADDR(imem_araddr),
        .RDATA(imem_rdata)
    );

    core #(CORE_ONLY) core_t (.CLK(CLK), .NRST(NRST),
    .DMEM_ARADDR(dmem_araddr),
    .DMEM_RDATA(dmem_rdata),
    .DMEM_AWADDR(dmem_awaddr),
    .DMEM_WDATA(dmem_wdata),
    .DMEM_AWVALID(dmem_awvalid),
    .IMEM_ARADDR(imem_araddr),
    .IMEM_RDATA(imem_rdata));



endmodule
