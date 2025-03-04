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
	output [AXI_AWIDTH-1:0]     IMEM_AXI_ARADDR,
    output reg                  IMEM_AXI_ARVALID,
    input                       IMEM_AXI_ARREADY,
    // Read Data Bus
    input  [AXI_DWIDTH-1:0]     IMEM_AXI_RDATA,
    input  [1:0]                IMEM_AXI_RRESP,
    input                       IMEM_AXI_RVALID,
    output reg                  IMEM_AXI_RREADY,

	// *** CONTROL SIGNAL INTERFACE ***
	// INSTRUCTIONS
	input						C_INSTR_FETCH,
	output reg					C_FETCH_DONE,
	output reg [31:0] 			INSTRUCTION,
	// PC UPDATES
	input						C_PC_UPDATE,
	input						C_ISBRANCH,
	input [31:0] 				BRANCH_IMM,
	input						C_ISJAL,
	input [31:0]				JAL_IMM,

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
				if (ISBRANCH)
					PC <= BRANCH_IMM + PC;
				else if (ISJAL)
					PC <= JAL_IMM + PC;
				else
					PC <= PC + 4;
			end
			else;
		end
	end

	assign IMEM_AXI_ARRADDR = PC;

	// READ ADDRESS CHANNEL (MASTER)
	always @(posedge CLK)
	begin
		if (!NRST)
			IMEM_AXI_ARVALID <= 0;
		else if (C_INSTR_FETCH)
		begin
			// KEEP READY ASSERTED UNTIL READY HAPPENS => They should stop simultaneously
			if (!IMEM_AXI_ARREADY)
				IMEM_AXI_ARVALID <= 1;
			else
				IMEM_AXI_ARVALID <= 0;
		end
		else
			IMEM_AXI_ARVALID <= 0;
	end

	// READ DATA CHANNEL (MASTER)
	always @(posedge CLK)
	begin
		if (!NRST)
		begin
			C_FETCH_DONE <= 1'b0;
			IMEM_AXI_RREADY <= 0;
		end
		else if (C_INSTR_FETCH)
			begin
				if (IMEM_AXI_RVALID & IMEM_AXI_ARREADY & IMEM_AXI_ARVALID & (AXI_RRESP == 2'b00))
				begin
					IMEM_AXI_RREADY <= 1;
					INSTRUCTION <= IMEM_AXI_RDATA;
					C_FETCH_DONE <= 1'b1;
				end
				else
				begin
					C_FETCH_DONE <= 1'b0;
					IMEM_AXI_RREADY <= 0;
				end
			end
		else
			begin
				C_FETCH_DONE <= 1'b0;
				IMEM_AXI_RREADY <= 0;
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