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
	output reg					BUSY,
	output	 					DONE,
	// PC UPDATES
	input 						FLUSH,
	input						PC_WRITE,
	input [31:0]				PC_NEXT,

	// *** PROGRAM COUNTER ***
	output reg [31:0]			PC
);

always @(posedge CLK)
begin
	if (!NRST)
		PC <= PC_INIT;
	else
	begin
		if (PC_WRITE)
			PC <= PC_NEXT;
		else;
	end
end

assign DONE = (AXI_RVALID & AXI_ARREADY & AXI_ARVALID & (AXI_RRESP == 2'b00)) ? 1'b1 : 1'b0;
assign AXI_ARADDR = PC;
// ==========================
// AXI READ ADDRESS CHANNEL
// ==========================

always @(posedge CLK)
begin
	if (!NRST)
	begin
		AXI_ARVALID <= 0;
		AXI_RREADY <= 0;
		BUSY <= 1; // (BUSY == 1) indicates the instruction-fetch is busy fetching -> Enable on reset since then instruction fetching restarts
		INSTRUCTION <= 32'h00000013;
	end
	else if (FLUSH)
	begin
		AXI_ARVALID <= 0;
		AXI_RREADY <= 0;
		BUSY <= 1; // (BUSY == 1) indicates the instruction-fetch is busy fetching -> Enable on reset since then instruction fetching restarts
		INSTRUCTION <= 32'h00000013;
	end
	else if (PC_WRITE | BUSY) // Fetch an instruction on each PC_WRITE
	begin
		// Always ready to receive instructions on C_INSTR_FETCH
		if (AXI_RVALID & AXI_ARREADY & AXI_ARVALID & (AXI_RRESP == 2'b00))
		begin
			AXI_ARVALID <= 1'b0;
			AXI_RREADY <= 1'b0;
			BUSY <= 1'b0; // Set instruction fetch to 0
			INSTRUCTION <= AXI_RDATA;
		end
		else
		begin
			AXI_ARVALID <= 1'b1;
			AXI_RREADY <= 1'b1;
			BUSY <= 1'b1; // Set instruction fetch to 1 -> Keep fetching until fetch is done
			// INSTRUCTION <= 32'h00000013;
		end
	end
	else
	begin
		AXI_ARVALID <= 1'b0;
		AXI_RREADY <= 1'b0;
		// INSTRUCTION <= 32'h00000013;
	end
end

endmodule


/**
We need a separate instruction fetch signal which lasts 1 clock cycle
- It should trigger at the beginning of each 
*/