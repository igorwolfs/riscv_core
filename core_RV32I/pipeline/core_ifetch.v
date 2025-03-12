`timescale 1ns/10ps


module core_ifetch #(
	parameter PC_INIT = 32'h0,
    parameter AXI_AWIDTH = 4,
    parameter AXI_DWIDTH = 32)
(
    // SYSTEM
	input  CLK, NRST,

    // *** INSTRUCTION MEMORY INTERFACE ***
    // Read Address Bus
	output [AXI_AWIDTH-1:0]     AXI_ARADDR,
    output reg                  AXI_ARVALID,
    input                       AXI_ARREADY,
    // Read Data Bus
    input  [AXI_DWIDTH-1:0]     AXI_RDATA,
    input  [1:0]                AXI_RRESP,
    input                       AXI_RVALID,
    output reg                  AXI_RREADY,

	// *** CONTROL SIGNAL INTERFACE ***
	// INSTRUCTIONS
	output reg [31:0] 			INSTRUCTION,
	// PC UPDATES
	input						HCU_STALLPIPE,
	input [31:0]				PC_NEXT,

	// *** PROGRAM COUNTER ***
	output reg [31:0]			PC
);

always @(posedge CLK)
begin
	if (!NRST)
		PC <= PC_INIT;
	else
	// ONLY INCREMENT IF FETCHING ISN'T IN PROGRESS => PC_INCR should be controlled by control circuitry, triggered at the end of the pipeline cycle
	begin
		if (!HCU_STALLPIPE)
			PC <= PC_NEXT;
		else;
	end
end

assign AXI_ARADDR = PC;

// ==========================
// AXI READ ADDRESS CHANNEL
// ==========================

// Make sure to latch HCU_STALLPIPE somewhere and only continue fetching if it (or it's latch) is enabled
// Make sure to set the register back to 0 on success

reg ifetch_en;

always @(posedge CLK)
begin
	if (!NRST)
	begin
		ifetch_en <= 0;
		AXI_ARVALID <= 0;
		AXI_RREADY <= 0;
		INSTRUCTION <= 32'hDEADBEEF;
	end
	else if (!HCU_STALLPIPE || ifetch_en)
	begin
		// Always ready to receive instructions on C_INSTR_FETCH
		if (AXI_RVALID & AXI_ARREADY & AXI_ARVALID & (AXI_RRESP == 2'b00))
		begin
			AXI_ARVALID <= 1'b0;
			AXI_RREADY <= 1'b0;
			ifetch_en <= 1'b0; // Set instruction fetch to 0
			INSTRUCTION <= AXI_RDATA;
		end
		else
			begin
			AXI_ARVALID <= 1'b1;
			AXI_RREADY <= 1'b1;
			ifetch_en <= 1'b1; // Set instruction fetch to 1 -> Keep fetching until fetch is done
			// INSTRUCTION <= 32'hDEADBEEF;
			end
	end
	else
	begin
		AXI_ARVALID <= 1'b0;
		AXI_RREADY <= 1'b0;
		// INSTRUCTION <= 32'hDEADBEEF;
	end
end

endmodule


/**
- PC register
SIGNALS
- IMEM AXI bus
- isbranch + branch_incr
- isjump + jump_incr

*/