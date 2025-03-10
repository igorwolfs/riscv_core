`timescale 1ns/10ps

module riscv_mcu
#(
    parameter INT_MEM_SIZE = 64,
    parameter AXI_AWIDTH = 32,
    parameter AXI_DWIDTH = 32,

    // UART
    parameter CLOCK_FREQUENCY = 100_000_000,
    parameter BAUD_RATE = 115_200,
    parameter DATA_BITS = 8,

    // Peripheral interfaces + Address Ss
    parameter S0_EN = 1'b1, // MEMORY
    parameter S1_EN = 1'b1, // UART
    parameter S2_EN = 1'b1, // TEST
    parameter ADDR_S0_START = 32'h00000000,
    parameter ADDR_S0_END = 32'h3FFFFFF0,
    parameter ADDR_S1_START = 32'h40000000,
    parameter ADDR_S1_END = 32'h4000000F,
    parameter ADDR_S2_START = 32'hF0000000, // END SIM / WRITE TO FILE
    parameter ADDR_S2_END = 32'hF0000007
)
(
    // *** SYSTEM PINS
    input CLK, input NRST,

    // *** IO
    input UART_RX_DSER,
    output UART_TX_DSER
);

// ! ********************* SIGNALS ***************************
// *** DATA MEMORY / PERIPHERAL INTERFACE ***
wire host_axi_aclk, host_axi_aresetn;
assign host_axi_aclk = CLK;
assign host_axi_aresetn = NRST;

// Write Address Bus
wire [AXI_AWIDTH-1:0] host_axi_awaddr;
wire host_axi_awvalid, host_axi_awready;
// Read Address Bus
wire [AXI_DWIDTH-1:0] host_axi_wdata;
wire [3:0] host_axi_wstrb;
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
assign imem_axi_aclk = CLK;
assign imem_axi_aresetn = NRST;

// Write Address Bus
wire [AXI_AWIDTH-1:0] imem_axi_awaddr;
wire imem_axi_awvalid, imem_axi_awready;
// Write Data Bus
wire [AXI_DWIDTH-1:0] imem_axi_wdata;
wire [3:0] imem_axi_wstrb;
wire imem_axi_wvalid, imem_axi_wready;
// Response Bus
wire [1:0] imem_axi_bresp;
wire imem_axi_bvalid, imem_axi_bready;
// Read Address Bus
wire [AXI_AWIDTH-1:0] imem_axi_araddr;
wire imem_axi_arvalid, imem_axi_arready;
// Read Data Bus
wire [AXI_DWIDTH-1:0] imem_axi_rdata;
wire [1:0] imem_axi_rresp;
wire imem_axi_rvalid, imem_axi_rready;

// *** SLAVE INTERFACE 0 ***
wire s0_axi_aclk, s0_axi_aresetn;
assign s0_axi_aclk = CLK;
assign s0_axi_aresetn = NRST;

// Write Address Bus
wire [AXI_AWIDTH-1:0] s0_axi_awaddr;
wire s0_axi_awvalid, s0_axi_awready;
// Write Data Bus
wire [AXI_DWIDTH-1:0] s0_axi_wdata;
wire [3:0] s0_axi_wstrb;
wire s0_axi_wvalid, s0_axi_wready;
// Response Bus
wire [1:0] s0_axi_bresp;
wire s0_axi_bvalid, s0_axi_bready;
// Address Read Bus
wire [AXI_AWIDTH-1:0] s0_axi_araddr;
wire s0_axi_arvalid, s0_axi_arready;
// Data Read Bus
wire [AXI_DWIDTH-1:0] s0_axi_rdata;
wire [1:0] s0_axi_rresp;
wire s0_axi_rvalid, s0_axi_rready;

// *** SLAVE INTERFACE 1 ***
// Write Address Bus
wire s1_axi_aclk, s1_axi_aresetn;
assign s1_axi_aclk = CLK;
assign s1_axi_aresetn = NRST;

wire [AXI_AWIDTH-1:0] s1_axi_awaddr;
wire s1_axi_awvalid, s1_axi_awready;
// Write Data Bus
wire [AXI_DWIDTH-1:0] s1_axi_wdata;
wire [3:0] s1_axi_wstrb;
wire s1_axi_wvalid, s1_axi_wready;
// Response Bus
wire [1:0] s1_axi_bresp;
wire s1_axi_bvalid, s1_axi_bready;
// Address Read Bus
wire [AXI_AWIDTH-1:0] s1_axi_araddr;
wire s1_axi_arvalid, s1_axi_arready;
// Data Read Bus
wire [AXI_DWIDTH-1:0] s1_axi_rdata;
wire [1:0] s1_axi_rresp;
wire s1_axi_rvalid, s1_axi_rready;

// *** SLAVE INTERFACE 2 ***
wire s2_axi_aclk, s2_axi_aresetn;
assign s2_axi_aclk = CLK;
assign s2_axi_aresetn = NRST;

// Write Address Bus
wire [AXI_AWIDTH-1:0] s2_axi_awaddr;
wire s2_axi_awvalid, s2_axi_awready;
// Write Data Bus
wire [AXI_DWIDTH-1:0] s2_axi_wdata;
wire [3:0] s2_axi_wstrb;
wire s2_axi_wvalid, s2_axi_wready;
// Response Bus
wire [1:0] s2_axi_bresp;
wire s2_axi_bvalid, s2_axi_bready;
// Address Read Bus
wire [AXI_AWIDTH-1:0] s2_axi_araddr;
wire s2_axi_arvalid, s2_axi_arready;
// Data Read Bus
wire [AXI_DWIDTH-1:0] s2_axi_rdata;
wire [1:0] s2_axi_rresp;
wire s2_axi_rvalid, s2_axi_rready;

// ================================================================
// CORE
// ================================================================
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

// ================================================================
// BUS INTERCONNECT
// ================================================================

// Instantiate the bus_interconnect module
bus_interconnect #(
    .AXI_DWIDTH(AXI_DWIDTH),
    .AXI_AWIDTH(AXI_AWIDTH),
    .S0_EN(S0_EN),
    .S1_EN(S1_EN),
    .S2_EN(S2_EN),
    .ADDR_S0_START(ADDR_S0_START),
    .ADDR_S0_END(ADDR_S0_END),
    .ADDR_S1_START(ADDR_S1_START),
    .ADDR_S1_END(ADDR_S1_END),
    .ADDR_S2_START(ADDR_S2_START), // END SIM / WRITE TO FILE
    .ADDR_S2_END(ADDR_S2_END)

) bus_interconnect_inst (
    .ACLK(host_axi_aclk),
    .ARESETN(host_axi_aresetn),

    // HOST interface
    .H_AWADDR(host_axi_awaddr),
    .H_AWVALID(host_axi_awvalid),
    .H_AWREADY(host_axi_awready),
    .H_WDATA(host_axi_wdata),
    .H_WSTRB(host_axi_wstrb),
    .H_WVALID(host_axi_wvalid),
    .H_WREADY(host_axi_wready),
    .H_BRESP(host_axi_bresp),
    .H_BVALID(host_axi_bvalid),
    .H_BREADY(host_axi_bready),
    .H_ARADDR(host_axi_araddr),
    .H_ARVALID(host_axi_arvalid),
    .H_ARREADY(host_axi_arready),
    .H_RDATA(host_axi_rdata),
    .H_RRESP(host_axi_rresp),
    .H_RVALID(host_axi_rvalid),
    .H_RREADY(host_axi_rready),

    // IMEM interface
    .IMEM_AWADDR(imem_axi_awaddr), // IMEM does not write
    .IMEM_AWVALID(imem_axi_awvalid), // IMEM does not write
    .IMEM_AWREADY(imem_axi_awready),
    .IMEM_WDATA(imem_axi_wdata), // IMEM does not write
    .IMEM_WSTRB(imem_axi_wstrb), // IMEM does not write
    .IMEM_WVALID(imem_axi_wvalid), // IMEM does not write
    .IMEM_WREADY(imem_axi_wready),
    .IMEM_BRESP(imem_axi_bresp),
    .IMEM_BVALID(imem_axi_bvalid),
    .IMEM_BREADY(imem_axi_bready),
    .IMEM_ARADDR(imem_axi_araddr),
    .IMEM_ARVALID(imem_axi_arvalid),
    .IMEM_ARREADY(imem_axi_arready),
    .IMEM_RDATA(imem_axi_rdata),
    .IMEM_RRESP(imem_axi_rresp),
    .IMEM_RVALID(imem_axi_rvalid),
    .IMEM_RREADY(imem_axi_rready),


    // Slave 0 interface
    .S0_AWADDR(s0_axi_awaddr),
    .S0_AWVALID(s0_axi_awvalid),
    .S0_AWREADY(s0_axi_awready),
    .S0_WDATA(s0_axi_wdata),
    .S0_WSTRB(s0_axi_wstrb),
    .S0_WVALID(s0_axi_wvalid),
    .S0_WREADY(s0_axi_wready),
    .S0_BRESP(s0_axi_bresp),
    .S0_BVALID(s0_axi_bvalid),
    .S0_BREADY(s0_axi_bready),
    .S0_ARADDR(s0_axi_araddr),
    .S0_ARVALID(s0_axi_arvalid),
    .S0_ARREADY(s0_axi_arready),
    .S0_RDATA(s0_axi_rdata),
    .S0_RRESP(s0_axi_rresp),
    .S0_RVALID(s0_axi_rvalid),
    .S0_RREADY(s0_axi_rready),

    // Slave 1 interface
    .S1_AWADDR(s1_axi_awaddr),
    .S1_AWVALID(s1_axi_awvalid),
    .S1_AWREADY(s1_axi_awready),
    .S1_WDATA(s1_axi_wdata),
    .S1_WSTRB(s1_axi_wstrb),
    .S1_WVALID(s1_axi_wvalid),
    .S1_WREADY(s1_axi_wready),
    .S1_BRESP(s1_axi_bresp),
    .S1_BVALID(s1_axi_bvalid),
    .S1_BREADY(s1_axi_bready),
    .S1_ARADDR(s1_axi_araddr),
    .S1_ARVALID(s1_axi_arvalid),
    .S1_ARREADY(s1_axi_arready),
    .S1_RDATA(s1_axi_rdata),
    .S1_RRESP(s1_axi_rresp),
    .S1_RVALID(s1_axi_rvalid),
    .S1_RREADY(s1_axi_rready),

    // Slave 2 interface
    .S2_AWADDR(s2_axi_awaddr),
    .S2_AWVALID(s2_axi_awvalid),
    .S2_AWREADY(s2_axi_awready),
    .S2_WDATA(s2_axi_wdata),
    .S2_WSTRB(s2_axi_wstrb),
    .S2_WVALID(s2_axi_wvalid),
    .S2_WREADY(s2_axi_wready),
    .S2_BRESP(s2_axi_bresp),
    .S2_BVALID(s2_axi_bvalid),
    .S2_BREADY(s2_axi_bready),
    .S2_ARADDR(s2_axi_araddr),
    .S2_ARVALID(s2_axi_arvalid),
    .S2_ARREADY(s2_axi_arready),
    .S2_RDATA(s2_axi_rdata),
    .S2_RRESP(s2_axi_rresp),
    .S2_RVALID(s2_axi_rvalid),
    .S2_RREADY(s2_axi_rready)
);

// ================================================================
// PERIPHERALS
// ================================================================

// *** MEMORY ***
// ADDR S 32h00000000-32h3ffffffff
memory #(
    .INT_MEM_SIZE(INT_MEM_SIZE),
    .AXI_AWIDTH(AXI_AWIDTH),
    .AXI_DWIDTH(AXI_DWIDTH)
) memory_inst (
    .AXI_ACLK(s0_axi_aclk),
    .AXI_ARESETN(s0_axi_aresetn),
    .AXI_AWADDR(s0_axi_awaddr),
    .AXI_AWVALID(s0_axi_awvalid),
    .AXI_AWREADY(s0_axi_awready),
    .AXI_WDATA(s0_axi_wdata),
    .AXI_WSTRB(s0_axi_wstrb),
    .AXI_WVALID(s0_axi_wvalid),
    .AXI_WREADY(s0_axi_wready),
    .AXI_BRESP(s0_axi_bresp),
    .AXI_BVALID(s0_axi_bvalid),
    .AXI_BREADY(s0_axi_bready),
    .AXI_ARADDR(s0_axi_araddr),
    .AXI_ARVALID(s0_axi_arvalid),
    .AXI_ARREADY(s0_axi_arready),
    .AXI_RDATA(s0_axi_rdata),
    .AXI_RRESP(s0_axi_rresp),
    .AXI_RVALID(s0_axi_rvalid),
    .AXI_RREADY(s0_axi_rready)
);

// *** UART ***
// ADDR S 32h40000000-32h5ffffffff
uart_axi4lite #(
    .AXI_AWIDTH(AXI_AWIDTH), 
    .AXI_DWIDTH(AXI_DWIDTH), 
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY), 
    .BAUD_RATE(115_200), 
    .DATA_BITS(DATA_BITS)
) uart_axi4lite_inst (
    .AXI_ACLK(s1_axi_aclk), 
    .AXI_ARESETN(s1_axi_aresetn),
    .AXI_AWADDR(s1_axi_awaddr),
    .AXI_AWVALID(s1_axi_awvalid),
    .AXI_AWREADY(s1_axi_awready),
    .AXI_WDATA(s1_axi_wdata),
    .AXI_WSTRB(s1_axi_wstrb),
    .AXI_WVALID(s1_axi_wvalid),
    .AXI_WREADY(s1_axi_wready),
    .AXI_BRESP(s1_axi_bresp),
    .AXI_BVALID(s1_axi_bvalid), 
    .AXI_BREADY(s1_axi_bready),
    .AXI_ARADDR(s1_axi_araddr), 
    .AXI_ARVALID(s1_axi_arvalid),
    .AXI_ARREADY(s1_axi_arready), 
    .AXI_RDATA(s1_axi_rdata),
    .AXI_RRESP(s1_axi_rresp), 
    .AXI_RVALID(s1_axi_rvalid),
    .AXI_RREADY(s1_axi_rready), 
    .TX_DSER(UART_TX_DSER),
    .RX_DSER(UART_RX_DSER)
);

// *** AXI File Handler ***
// ADDR S 32h60000000-32h6ffffffff
axi_file_handler #(
    .ADDR_WRITE_TO_FILE(32'hf0000000),
    .ADDR_STOP_SIM(32'hf0000004),
    .AXI_AWIDTH(AXI_AWIDTH),
    .AXI_DWIDTH(AXI_DWIDTH)
    ) axi_file_handler_inst (
        .AXI_ACLK(s2_axi_aclk),
        .AXI_ARESETN(s2_axi_aresetn),
        .AXI_AWADDR(s2_axi_awaddr),
        .AXI_AWVALID(s2_axi_awvalid),
        .AXI_AWREADY(s2_axi_awready),
        .AXI_WDATA(s2_axi_wdata),
        .AXI_WSTRB(s2_axi_wstrb),
        .AXI_WVALID(s2_axi_wvalid),
        .AXI_WREADY(s2_axi_wready),
        .AXI_BRESP(s2_axi_bresp),
        .AXI_BVALID(s2_axi_bvalid),
        .AXI_BREADY(s2_axi_bready),
        .AXI_ARADDR(s2_axi_araddr),
        .AXI_ARVALID(s2_axi_arvalid),
        .AXI_ARREADY(s2_axi_arready),
        .AXI_RDATA(s2_axi_rdata),
        .AXI_RRESP(s2_axi_rresp),
        .AXI_RVALID(s2_axi_rvalid),
        .AXI_RREADY(s2_axi_rready)
    );

endmodule
