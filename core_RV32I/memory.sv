`timescale 1ns/10ps

`define TEST_ENABLED

module memory #(parameter INT_MEM_SIZE = 256,
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

parameter MEMMAX_ADDR_IDX = $clog2(INT_MEM_SIZE) + 1;

reg [31:0] ram [0:INT_MEM_SIZE-1];
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
    end
    // If both the write and the address write channel are valid => Write to memory
    else if (AXI_WVALID & AXI_AWVALID)
    begin
        if (AXI_AWREADY & AXI_WREADY)
        begin
            AXI_AWREADY <= 1'b0;
            AXI_WREADY <= 1'b0;
            AXI_BVALID <= 1'b0;
        end
        else
        begin
            AXI_AWREADY <= 1'b1;
            AXI_WREADY <= 1'b1;
            AXI_BVALID <= 1'b1;
            AXI_BRESP <= 2'b00;
            if (AXI_WSTRB[0]) ram[AXI_AWADDR[MEMMAX_ADDR_IDX:2]][7:0] <= AXI_WDATA[7:0];
            if (AXI_WSTRB[1]) ram[AXI_AWADDR[MEMMAX_ADDR_IDX:2]][15:8] <= AXI_WDATA[15:8];
            if (AXI_WSTRB[2]) ram[AXI_AWADDR[MEMMAX_ADDR_IDX:2]][23:16] <= AXI_WDATA[23:16];
            if (AXI_WSTRB[3]) ram[AXI_AWADDR[MEMMAX_ADDR_IDX:2]][31:24] <= AXI_WDATA[31:24];
        end
    end
    else
    begin
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
        AXI_RRESP <= 2'b00;
    end
    else
    begin
        if (AXI_ARVALID & AXI_RREADY)
        begin
            if (AXI_RVALID & AXI_ARREADY)
            begin
                AXI_RDATA <= 32'hDEADBEEF;
                AXI_RVALID <= 1'b0;
                AXI_ARREADY <= 1'b0;
                // SHOULD BE REPLACED BY MEMREAD
            end
            else
            begin
                AXI_RDATA <= ram[AXI_ARADDR[MEMMAX_ADDR_IDX:2]];
                AXI_RVALID <= 1'b1;
                AXI_ARREADY <= 1'b1;
                AXI_RRESP <= 2'b00;
            end
        end
        else
        begin
            AXI_RVALID <= 1'b0;
            AXI_ARREADY <= 1'b0;
        end
    end
end



`ifdef TEST_ENABLED
string mem_path;
initial
begin
    if (!$value$plusargs("MEM_PATH=%s", mem_path)) mem_path = "/home/iwolfs/Work/Projects/fpga_project/risc5/riscv-riscof/riscv_core/tests/c_gen_uart/my.hex";
        $readmemh(mem_path, ram);    //"/home/iwolfs/Work/Projects/fpga_project/risc5/riscv-riscof/riscv_core/tests/c_gen_uart/my.hex";
                                    //  "/home/iwolfs/Work/Projects/fpga_project/risc5/riscv-riscof/riscof_work/rv32i_m/I/src/add-01.S/dut/my.hex";
    $display("Memory module initialized");
end
`else
initial begin
    $readmemh("/home/iwolfs/Work/Projects/fpga_project/risc5/riscv-riscof/riscv_core/tests/uart_physical_test/my.hex", ram);
end
`endif


endmodule
