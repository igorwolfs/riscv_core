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
// READ DATA / ADDRESS CHANNEL
// ================================



always @(posedge AXI_ACLK)
begin
    if (!AXI_ARESETN)
    begin
        AXI_RDATA <= 32'hDEADBEEF;
        AXI_RVALID <= 1'b0;
        AXI_ARREADY <= 1'b0;
    end
    else
    begin
        if (AXI_ARVALID & AXI_RREADY)
        begin
            if (AXI_RVALID & AXI_ARREADY)
            begin
                AXI_RVALID <= 1'b0;
                AXI_ARREADY <= 1'b0;
                // SHOULD BE REPLACED BY MEMREAD
                if (RISCOF_TEST_MODE)
                    AXI_RDATA <= IMEM_RDATA;
                else
                    AXI_RDATA <= ram[AXI_ARADDR];
            end
            else
            begin
                AXI_RVALID <= 1'b1;
                AXI_ARREADY <= 1'b1;
                AXI_RRESP <= 2'b00;
            end
        end
        else
        begin
            AXI_RVALID <= 1'b0;
            AXI_ARREADY <= 1'b0;
            AXI_RDATA <= IMEM_RDATA;
        end
    end
end

//! NOTE: write-instruction to instruction memory should never happen!
endmodule
