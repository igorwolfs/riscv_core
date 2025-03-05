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
	input						C_INSTR_FETCH,
	output reg [31:0] 			INSTRUCTION,
	// PC UPDATES
	input						C_PC_UPDATE,
	input						C_ISJUMP,  // branch taken / jump instruction
	input [31:0]				JUMP_INCR, // By how much we increment

	// *** PROGRAM COUNTER ***
	output reg 					PC
);

// PC UPDATES ON PC_UPDATE == 1
always @(posedge CLK)
begin
	if (!NRST)
		PC <= PC_INIT;
	else
	// ONLY INCREMENT IF FETCHING ISN'T IN PROGRESS => PC_INCR should be controlled by control circuitry, triggered at the end of the pipeline cycle
	begin
		if (PC_UPDATE)
		begin
			if (C_ISJUMP)
				PC <= PC + JUMP_INCR;
			else
				PC <= PC + 4;
		end
		else;
	end
end

assign AXI_ARRADDR = PC;

// ==========================
// AXI READ ADDRESS CHANNEL
// ==========================

always @(posedge CLK)
begin
	if (!NRST)
		AXI_ARVALID <= 0;
	else if (C_INSTR_FETCH)
	begin
		// KEEP READY ASSERTED UNTIL READY HAPPENS => They should stop simultaneously
		if (!AXI_ARREADY)
			AXI_ARVALID <= 1;
		else
			AXI_ARVALID <= 0;
	end
	else
		AXI_ARVALID <= 0;
end

// READ DATA CHANNEL (MASTER)
always @(posedge CLK)
begin
	if (!NRST)
	begin
		C_FETCH_DONE <= 1'b0;
		AXI_RREADY <= 0;
	end
	else if (C_INSTR_FETCH)
		begin
			if (AXI_RVALID & AXI_ARREADY & AXI_ARVALID & (AXI_RRESP == 2'b00))
			begin
				AXI_RREADY <= 1;
				INSTRUCTION <= AXI_RDATA;
				C_FETCH_DONE <= 1'b1;
			end
			else
			begin
				C_FETCH_DONE <= 1'b0;
				AXI_RREADY <= 0;
			end
		end
	else
		begin
			C_FETCH_DONE <= 1'b0;
			AXI_RREADY <= 0;
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