`timescale 1ns/10ps

module axi_file_handler #(
    parameter ADDR_WRITE_TO_FILE = 32'hF0000000,
    parameter ADDR_STOP_SIM = 32'hF0000004,
    parameter AXI_AWIDTH = 32,
    parameter AXI_DWIDTH = 32
)(
    input wire          AXI_ACLK,
    input wire          AXI_ARESETN,

    // AXI write address channel
    input wire [31:0]   AXI_AWADDR,
    input wire          AXI_AWVALID,
    output reg          AXI_AWREADY,

    // AXI write data channel
    input wire [31:0]   AXI_WDATA,
    input wire [3:0]    AXI_WSTRB,
    input wire          AXI_WVALID,
    output reg          AXI_WREADY,

    // AXI write response channel
    output reg [1:0]    AXI_BRESP,
    output reg          AXI_BVALID,
    input wire          AXI_BREADY,

    // AXI read address channel
    input wire [31:0]   AXI_ARADDR,
    input wire          AXI_ARVALID,
    output wire         AXI_ARREADY,

    // AXI read data channel
    output wire [31:0]  AXI_RDATA,
    output wire [1:0]   AXI_RRESP,
    output wire         AXI_RVALID,
    input wire          AXI_RREADY
);

integer file;
string sig_path;
// Assign outputs

// Open file for writing
initial
begin
    $display("Initializing sigwrite module");
    if (!$value$plusargs("SIG_PATH=%s", sig_path)) sig_path = "/home/iwolfs/Work/Projects/fpga_project/risc5/riscv-riscof/riscv_core/tests/add-01.S/dut/my.sig";
    // "/home/iwolfs/Work/Projects/fpga_project/risc5/riscv-riscof/riscof_work/rv32i_m/I/src/add-01.S/dut/my.sig";
    // "/home/iwolfs/Work/Projects/fpga_project/risc5/riscv-riscof/riscv_core/tests/c_gen_uart/my.sig";
	file = $fopen(sig_path, "w");
	if (file == 0)
	begin
		$display("Error: Could not open file %s for writing", sig_path);
		$finish;
	end
end

// AXI write address and data channel
always @(posedge AXI_ACLK)
begin
    if (!AXI_ARESETN)
	begin
        AXI_AWREADY <= 1'b0;
        AXI_WREADY <= 1'b0;
        AXI_BVALID <= 1'b0;
        AXI_BRESP <= 2'b00;
    end 
	else if (AXI_AWVALID && AXI_WVALID)
		begin
            $display("WRITING DATA TO AXI FILE HANLDER");
			if (AXI_AWREADY & AXI_WREADY)
			begin
                $display("DATA WRITE STARTING");
                $display("SETTING SIGNALS TO 0 0x%x", AXI_AWADDR);
				AXI_AWREADY <= 1'b0;
				AXI_WREADY <= 1'b0;
				AXI_BVALID <= 1'b0;
			end
			else
			begin
                $display("SETTING SIGNALS TO 1 0x%x, 0x%x, %d", AXI_AWADDR, ADDR_STOP_SIM, AXI_AWADDR == ADDR_STOP_SIM);
				AXI_AWREADY <= 1'b1;
				AXI_WREADY <= 1'b1;
				AXI_BVALID <= 1'b1;
				AXI_BRESP <= 2'b00;
				if (AXI_AWADDR == ADDR_WRITE_TO_FILE)
                begin
                    $display("WRITING TO FILE!\r\n");
					$fwrite(file, "%h\n", AXI_WDATA);
                end 
                else if (AXI_AWADDR == ADDR_STOP_SIM)
                begin
                    $display("Stopping simulation");
                    $fclose(file);
                    $finish;
                end
			end
		end
	else
	begin
        AXI_AWREADY <= 1'b0;
        AXI_WREADY <= 1'b0;
        AXI_BVALID <= 1'b0;
    end
end

//! NO AXI READ IN THIS MODULE
assign AXI_ARREADY = 1'b0;
assign AXI_RREADY = 1'b0;

endmodule
