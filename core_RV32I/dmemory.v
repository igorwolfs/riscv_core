`timescale 1ns/10ps

module dmemory #(parameter INT_DMEM_SIZE = 1024,
            parameter AXI_AWIDTH = 4,
            parameter AXI_DWIDTH = 32)
(
    // SYS
    input                       AXI_ACLK,
    input                       AXI_ARESETN,
    // Write address channel
    input [AXI_AWIDTH-1:0]      AXI_AWADDR,
    input                       AXI_AWVALID,
    output reg                  AXI_AWREADY,
    // Write data-channel
    input [AXI_DWIDTH-1:0]      AXI_WDATA,
    input [(AXI_DWIDTH/8)-1:0]  AXI_WSTRB,
    input                       AXI_WVALID,
    output reg                  AXI_WREADY,
    // Response channel
    output reg  [1:0]           AXI_BRESP,
    output reg                  AXI_BVALID,
    input                       AXI_BREADY,
    // Address read channel
    input [AXI_AWIDTH-1:0]      AXI_ARADDR,
    input  wire                 AXI_ARVALID,
    output reg                  AXI_ARREADY,
    // Read data channel
    output reg [AXI_DWIDTH-1:0] AXI_RDATA,
    output reg [1:0]            AXI_RRESP,
    output reg                  AXI_RVALID,
    input                       AXI_RREADY

);

reg [31:0] ram[INT_DMEM_SIZE-1:0];
// WRITE ADDRESS CHANNEL
always @(posedge AXI_ACLK)
begin
    if (!AXI_ARESETN)
        AXI_AWREADY <= 1'b0;
    else
    begin
        if (!AXI_AWREADY & AXI_AWVALID)
            AXI_AWREADY <= 1'b1;
        else
            AXI_AWREADY <= 1'b0;
    end
end

// WRITE DATA CHANNEL
always @(posedge AXI_ACLK)
begin
    if (!AXI_ARESETN)
        AXI_WREADY <= 1'b0;
    else
    begin
        if (!AXI_WREADY & AXI_WVALID)
            AXI_WREADY <= 1'b1; // Accept write data
        else
            AXI_WREADY <= 1'b0;
    end
end

// WRITE READY CHANNEL

always @(posedge AXI_ACLK)
begin
    // If both the write and the address write channel are valid => Write to memory
    if (AXI_WREADY & AXI_WVALID & AXI_AWREADY & AXI_AWVALID)
    begin
        if (AXI_WSTRB[0]) ram[AXI_AWADDR][7:0] <= AXI_WDATA[7:0];
        if (AXI_WSTRB[1]) ram[AXI_AWADDR][15:8] <= AXI_WDATA[15:8];
        if (AXI_WSTRB[2]) ram[AXI_AWADDR][23:16] <= AXI_WDATA[23:16];
        if (AXI_WSTRB[3]) ram[AXI_AWADDR][31:24] <= AXI_WDATA[31:24];
    end
    else;
end

// WRITE RESPONSE CHANNEL
always @(posedge AXI_ACLK)
begin
    if (!AXI_ARESETN)
        AXI_BVALID <= 1'b0;
    if (!AXI_BVALID & AXI_WREADY & AXI_WVALID & AXI_AWREADY & AXI_AWVALID)
    begin
        AXI_BRESP <= 2'b00;
        AXI_BVALID <= 1'b1;
    end
    else
        AXI_BVALID <= 1'b0;
end

// READ ADDRESS CHANNEL
always @(posedge AXI_ACLK)
begin
    if (!AXI_ARESETN)
        AXI_ARREADY <= 1'b0;
    else
        begin
        if (AXI_ARVALID & !AXI_ARREADY)
            AXI_ARREADY <= 1;
        else
            AXI_ARREADY <= 0;
        end
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
        if (!AXI_RVALID & AXI_RREADY & AXI_ARREADY)
        begin
            AXI_RVALID <= 1'b1;
            AXI_RRESP <= 2'b00;
            AXI_RDATA <= ram[AXI_ARADDR];
        end // Assume that AXI_RREADY is high for one clock-cycle longer than AXI_RVALID
        else if (AXI_RVALID & AXI_RREADY)
            AXI_RVALID <= 1'b0;
        else;
    end
end

endmodule
