`timescale 1ns/10ps

module imemory #(parameter IMEM_SIZE = 1024,
        parameter AXI_AWIDTH = 4,
        parameter AXI_DWIDTH = 32)
        (
    // SYS
    input                       AXI_ACLK,
    input                       AXI_ARESETN,
    /*
    // Write address Bus
    input [AXI_AWIDTH-1:0]      AXI_AWADDR,
    input                       AXI_AWVALID,
    output reg                  AXI_AWREADY,
    // Write data-Bus
    input [AXI_DWIDTH-1:0]      AXI_WDATA,
    input [(AXI_DWIDTH/8)-1:0]  AXI_WSTRB,
    input                       AXI_WVALID,
    output reg                  AXI_WREADY,
    // Response Bus
    output reg  [1:0]           AXI_BRESP,
    output reg                  AXI_BVALID,
    input                       AXI_BREADY,
    */
    // Address read Bus
    input [AXI_AWIDTH-1:0]      AXI_ARADDR,
    input  wire                 AXI_ARVALID,
    output reg                  AXI_ARREADY,
    // Read data Bus
    output reg [AXI_DWIDTH-1:0] AXI_RDATA,
    output reg [1:0]            AXI_RRESP,
    output reg                  AXI_RVALID,
    input                       AXI_RREADY
);

reg [31:0] ram [IMEM_SIZE-1:0];

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
                AXI_RDATA <= ram[AXI_ARADDR];
            end
            else if (AXI_RVALID & AXI_RREADY)
                AXI_RVALID <= 1'b0;
        end
end

//! NOTE: write-instruction to instruction memory should never happen!
endmodule
