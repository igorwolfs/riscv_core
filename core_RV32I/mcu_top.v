`timescale 1ns/10ps

module riscv_mcu
#(
    parameter INT_MEM_SIZE = 512,
    parameter AXI_AWIDTH = 32,
    parameter AXI_DWIDTH = 32,

    // UART
    parameter CLOCK_FREQUENCY = 100_000_000,
    parameter BAUD_RATE = 115_200,
    parameter DATA_BITS = 8,

    // Peripheral interfaces + Address Ss
    parameter S0_EN = 1'b1, // MEMORY
    parameter S1_EN = 1'b1, // UART
    parameter S2_EN = 1'b0, // TEST
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
    output UART_TX_DSER,
    output NRST_LED // LED TO TEST RESET
);

assign NRST_LED = NRST;

// ! ********************* SIGNALS ***************************
// *** DATA MEMORY / PERIPHERAL INTERFACE ***
wire host_axi_aclk, host_axi_aresetn;
assign host_axi_aclk = CLK;
assign host_axi_aresetn = NRST;

`AXI_WIRES(host_axi_, AXI_AWIDTH, AXI_DWIDTH);


// *** INSTRUCTION MEMORY INTERFACE ***
wire imem_axi_aclk, imem_axi_aresetn;
assign imem_axi_aclk = CLK;
assign imem_axi_aresetn = NRST;

`AXI_WIRES(imem_axi_, AXI_AWIDTH, AXI_DWIDTH);


// *** SLAVE INTERFACE 0 ***
wire s0_axi_aclk, s0_axi_aresetn;
assign s0_axi_aclk = CLK;
assign s0_axi_aresetn = NRST;

`AXI_WIRES(s0_axi_, AXI_AWIDTH, AXI_DWIDTH);


// *** SLAVE INTERFACE 1 ***
// Write Address Bus
wire s1_axi_aclk, s1_axi_aresetn;
assign s1_axi_aclk = CLK;
assign s1_axi_aresetn = NRST;

`AXI_WIRES(s1_axi_, AXI_AWIDTH, AXI_DWIDTH);


// *** SLAVE INTERFACE 2 ***
wire s2_axi_aclk, s2_axi_aresetn;
assign s2_axi_aclk = CLK;
assign s2_axi_aresetn = NRST;

`AXI_WIRES(s2_axi_, AXI_AWIDTH, AXI_DWIDTH);

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

    // Host axi-bus portmap
    `AXI_PORTMAP(HOST_AXI_, host_axi_),

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

    // Master interfaces
    `AXI_PORTMAP(H_, host_axi_),
    `AXI_PORTMAP(IMEM_, imem_axi_),
    // Slave interfaces
    `AXI_PORTMAP(S0_, s0_axi_),
    `AXI_PORTMAP(S1_, s1_axi_),
    `AXI_PORTMAP(S2_, s2_axi_)

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
    `AXI_PORTMAP(AXI_, s0_axi_)
);

// *** UART ***
// ADDR S 32h40000000-32h5ffffffff
generate if (S1_EN) begin: UART_GEN
uart_axi4lite #(
    .AXI_AWIDTH(AXI_AWIDTH),
    .AXI_DWIDTH(AXI_DWIDTH),
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY), 
    .BAUD_RATE(115_200), 
    .DATA_BITS(DATA_BITS)
) uart_axi4lite_inst (
    .AXI_ACLK(s1_axi_aclk), 
    .AXI_ARESETN(s1_axi_aresetn),
    // Define axi port map
    `AXI_PORTMAP(AXI_, s1_axi_),
    // Serial wires
    .TX_DSER(UART_TX_DSER),
    .RX_DSER(UART_RX_DSER)
);
end
endgenerate

// *** AXI File Handler ***
// ADDR S 32h60000000-32h6ffffffff
generate if (S2_EN) begin: AXI_FILE_HANDLER_GEN
axi_file_handler #(
    .ADDR_WRITE_TO_FILE(32'hf0000000),
    .ADDR_STOP_SIM(32'hf0000004),
    .AXI_AWIDTH(AXI_AWIDTH),
    .AXI_DWIDTH(AXI_DWIDTH)
    ) axi_file_handler_inst (
        .AXI_ACLK(s2_axi_aclk),
        .AXI_ARESETN(s2_axi_aresetn),
        `AXI_PORTMAP(AXI_, s2_axi_)
    );
end
endgenerate
endmodule
