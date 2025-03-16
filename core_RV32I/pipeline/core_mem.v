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
    output [3:0] 				AXI_WSTRB,
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
	output	 					BUSY,
	input 						C_ISLOAD_SS, 	// Indicates load instruction
	input						ISLOADBS,		// 7th byte needs to be extended
	input						ISLOADHWS,		// 16th byte needs to be extended
	input						C_ISSTORE_SS,	// Indicates store instruction
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
assign AXI_WDATA = (STRB[0]) ? WDATA : (STRB[1]) ? WDATA << 8 : (STRB[2]) ? WDATA << 16 : WDATA << 24;

reg busy_store;
always @(posedge CLK)
begin
	if (!NRST)
	begin
		AXI_WVALID <= 1'b0;
		AXI_AWVALID <= 1'b0;
		AXI_BREADY <= 1'b0;
		busy_store <= 1'b0;
	end
	else if (C_ISSTORE_SS | busy_store)
	begin
		if (AXI_AWREADY & AXI_ARREADY & AXI_BVALID) // No response checking here
		begin
			AXI_WVALID <= 1'b0;
			AXI_AWVALID <= 1'b0;
			AXI_BREADY <= 1'b0;
			busy_store <= 1'b0;
		end
		else
		begin
			AXI_WVALID <= 1'b1;
			AXI_AWVALID <= 1'b1;
			AXI_BREADY <= 1'b1;
			busy_store <= 1'b1;
		end
	end
	else
	begin
		AXI_BREADY <= 0;
		AXI_WVALID <= 0;
		AXI_AWVALID <= 0;
	end
end


// ==========================
// AXI READ DATA / ADDRESS CHANNEL (Sending the response on succesfull read-data receipt)
// ==========================
// READ REGISTER
reg [31:0] reg_rdata;

// SHIFT
wire [7:0] byte_0, byte_1, byte_2, byte_3;

assign byte_0 = STRB[0] ? reg_rdata[7:0] : 8'h0;
assign byte_1 = STRB[1] ? reg_rdata[15:8] : 8'h0;
assign byte_2 = STRB[2] ? reg_rdata[23:16] : 8'h0;
assign byte_3 = STRB[3] ? reg_rdata[31:24] : 8'h0;

wire [31:0] reg_rdata_strb = {byte_3, byte_2, byte_1, byte_0};

wire [31:0] reg_rdata_sh = (STRB[0]) ?  {byte_3, byte_2, byte_1, byte_0} :
									(STRB[1]) ?  {{8'b0}, byte_3, byte_2, byte_1}:
									(STRB[2]) ? {{16'b0}, byte_3, byte_2} :
									{{24'b0}, byte_3};
// SET READ DATA
assign RDATA = (ISLOADBS) ? {{24{reg_rdata_sh[7]}}, reg_rdata_sh[7:0]} :
				(ISLOADHWS) ? {{16{reg_rdata_sh[15]}}, reg_rdata_sh[15:0]} :
				reg_rdata_sh;

assign AXI_ARADDR = ADDR;

// READ DATA CHANNEL (MASTER)
reg busy_load;
always @(posedge CLK)
begin
	if (!NRST)
	begin
		AXI_ARVALID <= 1'b0;
		AXI_RREADY <= 1'b0;
		busy_load <= 1'b0;
	end
	else if (C_ISLOAD_SS | busy_load)
	begin
		if (AXI_RVALID & AXI_ARREADY & AXI_ARVALID & (AXI_RRESP == 2'b00))
		begin
			AXI_ARVALID <= 1'b0;
			AXI_RREADY <= 1'b0;
			reg_rdata <= AXI_RDATA;
			busy_load <= 1'b0;
		end
		else
		begin
			AXI_ARVALID <= 1'b1;
			AXI_RREADY <= 1'b1;
			reg_rdata <= 32'hDEADBEEF;
			busy_load <= 1'b1;
		end
	end
	else
	begin
		AXI_ARVALID <= 1'b0;
		AXI_RREADY <= 1'b0;
		reg_rdata <= 32'hDEADBEEF;
	end
end

assign BUSY = (busy_load | busy_store);

endmodule

//! NOTE: load and store signal must only be triggered for 1 cycle (otherwise bus keeps fetching)