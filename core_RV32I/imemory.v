`timescale 1ns/10ps

module imemory #(parameter RISCOF_TEST_MODE = 0,
        parameter IMEM_SIZE = 1024,
        parameter AXI_AWIDTH = 4,
        parameter AXI_DWIDTH = 32)
        (
    // SYS
    input                       AXI_ACLK,
    input                       AXI_ARESETN,
    // Address read Bus
    input [AXI_AWIDTH-1:0]      AXI_ARADDR,
    input  wire                 AXI_ARVALID,
    output reg                  AXI_ARREADY,
    // Read data Bus
    output reg [AXI_DWIDTH-1:0] AXI_RDATA,
    output reg [1:0]            AXI_RRESP,
    output reg                  AXI_RVALID,
    input                       AXI_RREADY,
    // RISCOF TEST
    input [31:0]                IMEM_RDATA
);

reg [31:0] ram [IMEM_SIZE-1:0];

// ================================
// READ ADDRESS CHANNEL
// ================================

always @(posedge AXI_ACLK)
begin
    if (!AXI_ARESETN)
        AXI_ARREADY <= 1'b0;
    else
        if (!AXI_ARREADY & AXI_ARVALID)
            AXI_ARREADY <= 1'b1;
        else
            AXI_ARREADY <= 1'b0;
end

// ================================
// READ DATA CHANNEL
// ================================

always @(posedge AXI_ACLK)
begin
    if (!AXI_ARESETN)
    begin
        AXI_RDATA <= 32'hDEADBEEF;
        AXI_RVALID <= 1'b0;
    end
    else
        begin
            if (AXI_ARREADY & AXI_ARVALID & AXI_RREADY)
            begin
                AXI_RVALID <= 1'b1;
                AXI_RRESP <= 2'b00;
                // SHOULD BE REPLACED BY MEMREAD
                if (RISCOF_TEST_MODE)
                    AXI_RDATA <= IMEM_RDATA;
                else
                    AXI_RDATA <= ram[AXI_ARADDR];
            end
            else if (AXI_RVALID & AXI_RREADY)
                AXI_RVALID <= 1'b0;
        end
end

//! NOTE: write-instruction to instruction memory should never happen!
endmodule
