`timescale 1ns/10ps

module riscv_mcu
#(
    parameter INT_DMEM_SIZE = 1024 * 16,
    parameter INT_IMEM_SIZE = 1024 * 16,
    parameter AXI_AWIDTH = 4,
    parameter AXI_DWIDTH = 32
)
(
    // *** SYSTEM PINS
    input CLK, input NRST,

    // *** IO
    input RX_DSER,
    output TX_DSER
);

parameter INT_DMEM_BASE = 0;
parameter INT_IMEM_BASE = INT_DMEM_SIZE+INT_DMEM_BASE;

// ! ********************* SIGNALS ***************************
// *** DATA MEMORY / PERIPHERAL INTERFACE ***
wire host_axi_aclk, host_axi_aresetn;
// Write Address Bus
wire [AXI_AWIDTH-1:0] host_axi_awaddr;
wire host_axi_awvalid, host_axi_awready;
// Read Address Bus
wire [AXI_DWIDTH-1:0] host_axi_wdata;
wire [$clog2(AXI_DWIDTH-1)-1:0] host_axi_wstrb;
wire host_axi_wvalid, host_axi_wready;
// Response Bus
wire [1:0] host_axi_bresp;
wire host_axi_bvalid, host_axi_bready;
// Address Read Bus
wire [AXI_AWIDTH-1:0] host_axi_araddr;
wire host_axi_arvalid, host_axi_arready;
// Data Read Bus
wire [AXI_DWIDTH-1:0] host_axi_rdata;
wire [1:0] host_axi_rresp;
wire host_axi_rvalid, host_axi_rready;

// *** INSTRUCTION MEMORY INTERFACE ***
wire imem_axi_aclk, imem_axi_aresetn;
// Read Address Bus
wire [AXI_AWIDTH-1:0] imem_axi_araddr;
wire imem_axi_arvalid, imem_axi_arready;
// Read Data Bus
wire [AXI_DWIDTH-1:0] imem_axi_rdata;
wire [1:0] imem_axi_rresp;
wire imem_axi_rvalid, imem_axi_rready;

// ! ********************* ENTITIES ***************************


// *** Internal Data Memory ***
dmemory #(
    .INT_DMEM_SIZE(INT_DMEM_SIZE),
    .AXI_AWIDTH(AXI_AWIDTH),
    .AXI_DWIDTH(AXI_DWIDTH)
) dmem_inst (
    .AXI_ACLK(host_axi_aclk),
    .AXI_ARESETN(host_axi_aresetn),
    .AXI_AWADDR(host_axi_awaddr),
    .AXI_AWVALID(host_axi_awvalid),
    .AXI_AWREADY(host_axi_awready),
    .AXI_WDATA(host_axi_wdata),
    .AXI_WSTRB(host_axi_wstrb),
    .AXI_WVALID(host_axi_wvalid),
    .AXI_WREADY(host_axi_wready),
    .AXI_BRESP(host_axi_bresp),
    .AXI_BVALID(host_axi_bvalid),
    .AXI_BREADY(host_axi_bready),
    .AXI_ARADDR(host_axi_araddr),
    .AXI_ARVALID(host_axi_arvalid),
    .AXI_ARREADY(host_axi_arready),
    .AXI_RDATA(host_axi_rdata),
    .AXI_RRESP(host_axi_rresp),
    .AXI_RVALID(host_axi_rvalid),
    .AXI_RREADY(host_axi_rready)
);

// *** Internal Instruction Memory ***
imemory #(
    .IMEM_SIZE(INT_IMEM_SIZE),
    .AXI_AWIDTH(AXI_AWIDTH),
    .AXI_DWIDTH(AXI_DWIDTH)
) imem_inst (
    .AXI_ACLK(imem_axi_aclk),
    .AXI_ARESETN(imem_axi_aresetn),
    .AXI_ARADDR(imem_axi_araddr),
    .AXI_ARVALID(imem_axi_arvalid),
    .AXI_ARREADY(imem_axi_arready),
    .AXI_RDATA(imem_axi_rdata),
    .AXI_RRESP(imem_axi_rresp),
    .AXI_RVALID(imem_axi_rvalid),
    .AXI_RREADY(imem_axi_rready)
);

core_top #(
    .AXI_AWIDTH(AXI_AWIDTH),
    .AXI_DWIDTH(AXI_DWIDTH)
) core_inst (
    // SYSTEM
    .CLK(CLK),
    .NRST(NRST),

    // *** DATA MEMORY / PERIPHERAL INTERFACE ***
    .HOST_AXI_AWADDR(host_axi_awaddr),
    .HOST_AXI_AWVALID(host_axi_awvalid),
    .HOST_AXI_AWREADY(host_axi_awready),
    .HOST_AXI_WDATA(host_axi_wdata),
    .HOST_AXI_WSTRB(host_axi_wstrb),
    .HOST_AXI_WVALID(host_axi_wvalid),
    .HOST_AXI_WREADY(host_axi_wready),
    .HOST_AXI_BRESP(host_axi_bresp),
    .HOST_AXI_BVALID(host_axi_bvalid),
    .HOST_AXI_BREADY(host_axi_bready),
    .HOST_AXI_ARADDR(host_axi_araddr),
    .HOST_AXI_ARVALID(host_axi_arvalid),
    .HOST_AXI_ARREADY(host_axi_arready),
    .HOST_AXI_RDATA(host_axi_rdata),
    .HOST_AXI_RRESP(host_axi_rresp),
    .HOST_AXI_RVALID(host_axi_rvalid),
    .HOST_AXI_RREADY(host_axi_rready),

    // *** INSTRUCTION MEMORY INTERFACE ***
    .IMEM_AXI_ARADDR(imem_axi_araddr),
    .IMEM_AXI_ARVALID(imem_axi_arvalid),
    .IMEM_AXI_ARREADY(imem_axi_arready),
    .IMEM_AXI_RDATA(imem_axi_rdata),
    .IMEM_AXI_RRESP(imem_axi_rresp),
    .IMEM_AXI_RVALID(imem_axi_rvalid),
    .IMEM_AXI_RREADY(imem_axi_rready)
);

endmodule
