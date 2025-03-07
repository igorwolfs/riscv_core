`timescale 1ns/10ps

module dmemory #(parameter RISCOF_TEST_MODE = 0,
            parameter INT_DMEM_SIZE = 1024,
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
    input                       AXI_RREADY,

    // RISCOF
    input      [31:0]           DMEM_RDATA,
    input      [31:0]           DMEM_WDATA_READ,
    output reg [31:0]           DMEM_WDATA,
    output reg                  DMEM_WVALID
);

reg [31:0] ram[INT_DMEM_SIZE-1:0];

// ==========================================
// WRITE RESPONSE / DATA / ADDRESS CHANNEL
// ==========================================

always @(posedge AXI_ACLK)
begin
    if (!AXI_ARESETN)
    begin
        AXI_AWREADY <= 1'b0;
        AXI_WREADY <= 1'b0;
        AXI_BVALID <= 1'b0;
        DMEM_WVALID <= 1'b0;
    end
    // If both the write and the address write channel are valid => Write to memory
    if (AXI_WVALID & AXI_AWVALID)
    begin
        if (AXI_AWREADY & AXI_WREADY)
        begin
            AXI_AWREADY <= 1'b0;
            AXI_WREADY <= 1'b0;
            AXI_BVALID <= 1'b0;
            if (!RISCOF_TEST_MODE)
            begin
                if (AXI_WSTRB[0]) ram[AXI_AWADDR][7:0] <= AXI_WDATA[7:0];
                if (AXI_WSTRB[1]) ram[AXI_AWADDR][15:8] <= AXI_WDATA[15:8];
                if (AXI_WSTRB[2]) ram[AXI_AWADDR][23:16] <= AXI_WDATA[23:16];
                if (AXI_WSTRB[3]) ram[AXI_AWADDR][31:24] <= AXI_WDATA[31:24];
            end
            else
            begin
                DMEM_WVALID <= 1'b1;
                if (AXI_WSTRB[0])
                    DMEM_WDATA[7:0] <= AXI_WDATA[7:0];
                else
                    DMEM_WDATA[7:0] <= DMEM_WDATA_READ[7:0];
                if (AXI_WSTRB[1])
                    DMEM_WDATA[15:8] <= AXI_WDATA[15:8];
                else
                    DMEM_WDATA[15:8] <= DMEM_WDATA_READ[15:8];
                if (AXI_WSTRB[2])
                    DMEM_WDATA[23:16] <= AXI_WDATA[23:16];
                else
                    DMEM_WDATA[23:16] <= DMEM_WDATA_READ[23:16];
                if (AXI_WSTRB[3])
                    DMEM_WDATA[31:24] <= AXI_WDATA[31:24];
                else
                    DMEM_WDATA[31:24] <= DMEM_WDATA_READ[31:24];
            end
        end
        else
        begin
            DMEM_WVALID <= 1'b0;
            AXI_AWREADY <= 1'b1;
            AXI_WREADY <= 1'b1;
            AXI_BVALID <= 1'b1;
            AXI_BRESP <= 2'b00;
        end
    end
    else
    begin
        DMEM_WVALID <= 1'b0;
        AXI_AWREADY <= 1'b0;
        AXI_WREADY <= 1'b0;
        AXI_BVALID <= 1'b0;
    end
end

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
                    AXI_RDATA <= DMEM_RDATA;
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
            AXI_RDATA <= DMEM_RDATA;
        end
    end
end

endmodule
