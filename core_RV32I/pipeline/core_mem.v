`timescale 1ns/10ps


module core_mem #(
    parameter AXI_AWIDTH = 4,
    parameter AXI_DWIDTH = 32)
(
    // SYSTEM
	input  						CLK, NRST,
	// *** AXI INTERFACE ***
    // Write address channel
    output [AXI_AWIDTH-1:0]     AXI_AWADDR,
    output reg                  AXI_AWVALID,
    input 	                    AXI_AWREADY,
    // Write data-channel
    output [AXI_DWIDTH-1:0]     AXI_WDATA,
    output [(AXI_DWIDTH/8)-1:0] AXI_WSTRB,
    output reg                  AXI_WVALID,
    input  	                    AXI_WREADY,
    // Response channel
    input  [1:0]	            AXI_BRESP,
    input	                    AXI_BVALID,
    output reg                  AXI_BREADY, // When high, indicates store instruction is done
    // Address read channel
    output [AXI_AWIDTH-1:0]     AXI_ARADDR,
    output reg                  AXI_ARVALID,
    input	                    AXI_ARREADY,
    // Read data channel
    input  [AXI_DWIDTH-1:0]		AXI_RDATA,
    input  [1:0]	            AXI_RRESP,
    input 	                    AXI_RVALID,
    output reg                  AXI_RREADY, // When high, indicates that load instruction is done

	// ***  ***
	input 						C_DOLOAD, 	// Indicates load instruction
	input						ISLOADBS,	// 7th byte needs to be extended
	input						ISLOADHWS,	// 16th byte needs to be extended
	input						C_DOSTORE,	// Indicates store instruction
	input  	[31:0] 				ADDR, 	// LOAD / STORE ADDRESS: reg1 + imm
	input  	[31:0]				WDATA, 	// Data to be stored at ADDR
	output 	[31:0]				RDATA, 	// Data to be read -> should be shifted and handled according to signals (ISLOAD/ISLOADU)
	input 	[3:0]				STRB
);


assign AXI_WSTRB = STRB;

// ==========================
// AXI WRITE ADDRESS CHANNEL
// ==========================
assign AXI_AWADDR = ADDR;

always @(posedge CLK)
begin
	if (!NRST)
		AXI_AWVALID <= 0;
	else if (C_DOSTORE)
		begin
		if (!AXI_AWREADY)
			AXI_AWVALID <= 1;
		else if (AXI_AWVALID & AXI_AWREADY)
			AXI_AWVALID <= 0;
		else;
		end
	else
		AXI_AWVALID <= 0;
end

// ==========================
// AXI WRITE DATA CHANNEL
// ==========================
// Set write data according to strobe (data should be shifted to where first strobe occurs)
// The data to be written is 32-bit aligned, but it is supposed to be written to a non-32bit aligned region
assign AXI_WDATA = (STRB[0]) ? WDATA : (STRB[1]) ? WDATA << 8 : (STRB[2]) ? WDATA << 16 : WDATA << 24;

always @(posedge CLK)
begin
	if (!NRST)
		AXI_WVALID <= 0;
	else if (C_DOSTORE)
		if (!AXI_WREADY)
			AXI_WVALID <= 1;
		else if (AXI_WVALID & AXI_WREADY)
			AXI_WVALID <= 0;
		else;
	else
		AXI_WVALID <= 0;
end
// ==========================
// AXI RESPONSE HANDLING (Receiving the response)
// ==========================

always @(posedge CLK)
begin
	if (!NRST)
		AXI_BREADY <= 0;
	else if (C_DOSTORE)
		if (AXI_WVALID & AXI_AWVALID & AXI_WREADY & AXI_AWREADY & (AXI_BRESP == 2'b00) & AXI_BVALID)
		begin
			AXI_BREADY <= 1;
		end
		else
			AXI_BREADY <= 0;
	else
		AXI_BREADY <= 0;
end

// ==========================
// AXI READ ADDRESS CHANNEL
// ==========================
//! WARNING: ASYNCHRONOUS LOGIC HERE
assign AXI_ARADDR = ADDR;
always @(posedge CLK)
begin
	if (!NRST)
		AXI_ARVALID <= 0;
	else if (C_DOLOAD)
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

// ==========================
// AXI READ DATA CHANNEL (Sending the response on succesfull read-data receipt)
// ==========================
// READ REGISTER
reg [31:0] reg_rdata;
// DO MAGIC TO CHANGE THE READ INTO THE DESIRED BYTE FORMAT
//! NOTE: maybe it's an idea to move this to the the memory controller later (just data in and out on full strobe, memory controller handles the rest)
//! ALTHOUGH: it does mess things up for the write because having a strobe avoids the need for masking

// SHIFT
wire [31:0] reg_rdata_sh = (STRB[0]) ? reg_rdata :
									(STRB[1]) ? reg_rdata >> 8 :
									(STRB[2]) ? reg_rdata >> 16 :
									reg_rdata >> 24;
// SET READ DATA
assign RDATA = (ISLOADBS) ? {{24{reg_rdata_sh[24]}}, reg_rdata_sh[7:0]} :
				(ISLOADHWS) ? {{16{reg_rdata_sh[16]}}, reg_rdata_sh[15:0]} :
				reg_rdata_sh;


// READ DATA CHANNEL (MASTER)
always @(posedge CLK)
begin
	if (!NRST)
		AXI_RREADY <= 0;
	else if (C_DOLOAD)
		begin
			if (AXI_RVALID & AXI_ARREADY & AXI_ARVALID & (AXI_RRESP == 2'b00))
				begin
				AXI_RREADY <= 1;
				reg_rdata <= AXI_RDATA;
				end
			else
				AXI_RREADY <= 0;
		end
	else
		AXI_RREADY <= 0;
end


endmodule

/**
This module is supposed to be
- An AXI master communicating with the data-memory
- Supposed to perform LOAD / STORES based on register inputs + STRB from control circuit
- Load
	- strobe
	- 32-bit value out (shifted to the right depending on the strobe)
	- We should know here whether we are dealing with
		- signed or unsigned partial load -> if its unsigned the data should be extended first before its output to the registers
- Store
	- strobe
	- 32-bit rs2-value in
	- Sets the relevant strobe values
*/