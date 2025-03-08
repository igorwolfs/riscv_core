`timescale 1ns/10ps

module bus_interconnect #(
	parameter ADDR_RANGE0_START = 32'h20000000,
	parameter ADDR_RANGE0_END   = 32'h3FFFFFFF,
	parameter ADDR_RANGE1_START = 32'h40000000,
	parameter ADDR_RANGE1_END   = 32'h5FFFFFFF,
	parameter ADDR_RANGE2_START = 32'hF0000000, // END SIM / WRITE TO FILE
	parameter ADDR_RANGE2_END 	= 32'hF0000007,
	parameter H_PRIORITY = 1,
	parameter IMEM_PRIORITY = 0
)(
	input wire          ACLK,
	input wire          ARESETN,

	// HOST interface
	input wire [31:0]   H_AWADDR,
	input wire [2:0]    H_AWPROT,
	input wire          H_AWVALID,
	output wire         H_AWREADY,
	input wire [31:0]   H_WDATA,
	input wire [3:0]    H_WSTRB,
	input wire          H_WVALID,
	output wire         H_WREADY,
	output wire [1:0]   H_BRESP,
	output wire         H_BVALID,
	input wire          H_BREADY,
	input wire [31:0]   H_ARADDR,
	input wire [2:0]    H_ARPROT,
	input wire          H_ARVALID,
	output wire         H_ARREADY,
	output wire [31:0]  H_RDATA,
	output wire [1:0]   H_RRESP,
	output wire         H_RVALID,
	input wire          H_RREADY,

	// IMEM interface
	input wire [31:0]   IMEM_AWADDR,
	input wire [2:0]    IMEM_AWPROT,
	input wire          IMEM_AWVALID,
	output wire         IMEM_AWREADY,
	input wire [31:0]   IMEM_WDATA,
	input wire [3:0]    IMEM_WSTRB,
	input wire          IMEM_WVALID,
	output wire         IMEM_WREADY,
	output wire [1:0]   IMEM_BRESP,
	output wire         IMEM_BVALID,
	input wire          IMEM_BREADY,
	input wire [31:0]   IMEM_ARADDR,
	input wire [2:0]    IMEM_ARPROT,
	input wire          IMEM_ARVALID,
	output wire         IMEM_ARREADY,
	output wire [31:0]  IMEM_RDATA,
	output wire [1:0]   IMEM_RRESP,
	output wire         IMEM_RVALID,
	input wire          IMEM_RREADY,

	// Slave 0 interface
	output wire [31:0]  S0_AWADDR,
	output wire [2:0]   S0_AWPROT,
	output wire         S0_AWVALID,
	input wire          S0_AWREADY,
	output wire [31:0]  S0_WDATA,
	output wire [3:0]   S0_WSTRB,
	output wire         S0_WVALID,
	input wire          S0_WREADY,
	input wire [1:0]    S0_BRESP,
	input wire          S0_BVALID,
	output wire         S0_BREADY,
	output wire [31:0]  S0_ARADDR,
	output wire [2:0]   S0_ARPROT,
	output wire         S0_ARVALID,
	input wire          S0_ARREADY,
	input wire [31:0]   S0_RDATA,
	input wire [1:0]    S0_RRESP,
	input wire          S0_RVALID,
	output wire         S0_RREADY,

	// Slave 1 interface
	output wire [31:0]  S1_AWADDR,
	output wire [2:0]   S1_AWPROT,
	output wire         S1_AWVALID,
	input wire          S1_AWREADY,
	output wire [31:0]  S1_WDATA,
	output wire [3:0]   S1_WSTRB,
	output wire         S1_WVALID,
	input wire          S1_WREADY,
	input wire [1:0]    S1_BRESP,
	input wire          S1_BVALID,
	output wire         S1_BREADY,
	output wire [31:0]  S1_ARADDR,
	output wire [2:0]   S1_ARPROT,
	output wire         S1_ARVALID,
	input wire          S1_ARREADY,
	input wire [31:0]   S1_RDATA,
	input wire [1:0]    S1_RRESP,
	input wire          S1_RVALID,
	output wire         S1_RREADY,

	// Slave 2 interface
	output wire [31:0]  S2_AWADDR,
	output wire [2:0]   S2_AWPROT,
	output wire         S2_AWVALID,
	input wire          S2_AWREADY,
	output wire [31:0]  S2_WDATA,
	output wire [3:0]   S2_WSTRB,
	output wire         S2_WVALID,
	input wire          S2_WREADY,
	input wire [1:0]    S2_BRESP,
	input wire          S2_BVALID,
	output wire         S2_BREADY,
	output wire [31:0]  S2_ARADDR,
	output wire [2:0]   S2_ARPROT,
	output wire         S2_ARVALID,
	input wire          S2_ARREADY,
	input wire [31:0]   S2_RDATA,
	input wire [1:0]    S2_RRESP,
	input wire          S2_RVALID,
	output wire         S2_RREADY
);


	// ===========================================
	// BUS MUXING
	// ===========================================

	// *** MUX master states ***
	localparam H_MUX = 1'b0;
	localparam IMEM_MUX = 1'b1;
	
	// *** MUX Devices ***
	localparam S0_MUX = 1'b0;
	localparam S1_MUX = 1'b1;

    // *** Internal master signals ***
	wire [31:0]  m_awaddr;
	wire [2:0]   m_awprot;
	wire         m_awvalid;
	wire         m_awready;
	wire [31:0]  m_wdata;
	wire [3:0]   m_wstrb;
	wire         m_wvalid;
	wire         m_wready;
	wire [1:0]   m_bresp;
	wire         m_bvalid;
	wire         m_bready;
	wire [31:0]  m_araddr;
	wire [2:0]   m_arprot;
	wire         m_arvalid;
	wire         m_arready;
	wire [31:0]  m_rdata;
	wire [1:0]   m_rresp;
	wire         m_rvalid;
	wire         m_rready;


	// ========================================
	// MUXING
	// ========================================

	// *** WRITE ADDRESS / DATA CHANNEL + MEMORY WRITE MUX ***
	reg SM_mux_swrite;
	always @(posedge ACLK)
	begin
		if (!ARESETN)
		begin
			SM_mux_mwrite <= H_MUX;
			SM_mux_swrite <= S0_MUX;
		end
		else
		begin
			if (H_AWREADY & H_WVALID)
			begin
				SM_mux_mwrite <= H_MUX;
				// MUX TO SLAVES TO H
				if (H_AWADDR >= ADDR_RANGE0_START && H_AWADDR <= ADDR_RANGE0_END)
				begin
					SM_mux_swrite <= S0_MUX;
				end
				else if (H_AWADDR >= ADDR_RANGE1_START && H_AWADDR <= ADDR_RANGE1_END)
				begin
					SM_mux_swrite <= S1_MUX;
				end
			end
			else if (IMEM_AWREADY & IMEM_WVALID)
			begin
				SM_mux_mwrite <= IMEM_MUX;
				// MUX SLAVES TO IMEM
				if (IMEM_AWADDR >= ADDR_RANGE0_START && IMEM_AWADDR <= ADDR_RANGE0_END)
				begin
					SM_mux_swrite <= S0_MUX;
				end
				else if (IMEM_AWADDR >= ADDR_RANGE1_START && IMEM_AWADDR <= ADDR_RANGE1_END)
				begin
					SM_mux_swrite <= S1_MUX;
				end
			end
			else
			begin
				SM_mux_mwrite <= H_MUX;
				// MUX TO H BY DEFAULT
				if (H_AWADDR >= ADDR_RANGE0_START && H_AWADDR <= ADDR_RANGE0_END)
				begin
					SM_mux_swrite <= S0_MUX;
				end
				else if (H_AWADDR >= ADDR_RANGE1_START && H_AWADDR <= ADDR_RANGE1_END)
				begin
					SM_mux_swrite <= S1_MUX;
				end
			end
		end
	end

	

	// *** READ ADDRESS / DATA CHANNEL + MEMORY READ MUX ***
	reg SM_mux_sread;
	reg SM_mux_mread;

	always @(posedge ACLK)
	begin
		if (!ARESETN)
		begin
			SM_mux_sread <= S0_MUX;
			SM_mux_mread <= H_MUX;
		end
		else
		begin
			if (IMEM_ARVALID & IMEM_RREADY)
			begin
				SM_mux_mread <= IMEM_MUX;
				if (IMEM_ARADDR >= ADDR_RANGE0_START && IMEM_ARADDR <= ADDR_RANGE0_END)
				begin
					SM_mux_sread <= S0_MUX;
				end
				else if (IMEM_ARADDR >= ADDR_RANGE1_START && IMEM_ARADDR <= ADDR_RANGE1_END)
				begin
					SM_mux_sread <= S1_MUX;
				end
			end
			else if (H_ARVALID & H_RREADY)
			begin
				SM_mux_mread <= H_MUX;
				if (H_ARADDR >= ADDR_RANGE0_START && H_ARADDR <= ADDR_RANGE0_END)
				begin
					SM_mux_sread <= S0_MUX;
				end
				else if (H_ARADDR >= ADDR_RANGE1_START && H_ARADDR <= ADDR_RANGE1_END)
				begin
					SM_mux_sread <= S1_MUX;
				end
			end
			else
			begin
				SM_mux_mread <= IMEM_MUX;
				if (IMEM_ARADDR >= ADDR_RANGE0_START && IMEM_ARADDR <= ADDR_RANGE0_END)
				begin
					SM_mux_sread <= S0_MUX;
				end
				else if (IMEM_ARADDR >= ADDR_RANGE1_START && IMEM_ARADDR <= ADDR_RANGE1_END)
				begin
					SM_mux_sread <= S1_MUX;
				end
			end
		end
	end

	///////////////////////////////////
	// WRITE ADDRESS -> SLAVE
	///////////////////////////////////
	assign S0_AWVALID = (SM_mux_swrite == S0_MUX) ? m_awvalid : 1'b0;
	assign S0_AWADDR  = (SM_mux_swrite == S0_MUX) ? m_awaddr  : 32'b0;
	assign S0_AWPROT  = (SM_mux_swrite == S0_MUX) ? m_awprot  : 3'b0;
	
	assign S1_AWVALID = (SM_mux_swrite == S1_MUX) ? m_awvalid : 1'b0;
	assign S1_AWADDR  = (SM_mux_swrite == S1_MUX) ? m_awaddr  : 32'b0;
	assign S1_AWPROT  = (SM_mux_swrite == S1_MUX) ? m_awprot  : 3'b0;
	
	assign m_awready  = (SM_mux_swrite == S0_MUX) ? S0_AWREADY :
						(SM_mux_swrite == S1_MUX) ? S1_AWREADY : 1'b0;
	
	
	///////////////////////////////////
	// WRITE DATA -> SLAVE
	///////////////////////////////////
	assign S0_WVALID = (SM_mux_swrite == S0_MUX) ? m_wvalid : 1'b0;
	assign S0_WDATA  = (SM_mux_swrite == S0_MUX) ? m_wdata  : 32'b0;
	assign S0_WSTRB  = (SM_mux_swrite == S0_MUX) ? m_wstrb  : 4'b0;
	
	assign S1_WVALID = (SM_mux_swrite == S1_MUX) ? m_wvalid : 1'b0;
	assign S1_WDATA  = (SM_mux_swrite == S1_MUX) ? m_wdata  : 32'b0;
	assign S1_WSTRB  = (SM_mux_swrite == S1_MUX) ? m_wstrb  : 4'b0;
	
	assign m_wready  = (SM_mux_swrite == S0_MUX) ? S0_WREADY :
					   (SM_mux_swrite == S1_MUX) ? S1_WREADY : 1'b0;
	
	
	///////////////////////////////////
	// WRITE RESPONSE <- SLAVE
	///////////////////////////////////
	assign m_bresp  = (SM_mux_swrite == S0_MUX) ? S0_BRESP :
					  (SM_mux_swrite == S1_MUX) ? S1_BRESP : 2'b0;
	assign m_bvalid = (SM_mux_swrite == S0_MUX) ? S0_BVALID :
					  (SM_mux_swrite == S1_MUX) ? S1_BVALID : 1'b0;
	
	assign S0_BREADY = (SM_mux_swrite == S0_MUX) ? m_bready : 1'b0;
	assign S1_BREADY = (SM_mux_swrite == S1_MUX) ? m_bready : 1'b0;
	
	
	// READ ADDR -> SLAVE
	assign S0_ARVALID = (SM_mux_sread == S0_MUX) ? m_arvalid : 1'b0;
	assign S0_ARADDR  = (SM_mux_sread == S0_MUX) ? m_araddr  : 32'b0;
	assign S0_ARPROT  = (SM_mux_sread == S0_MUX) ? m_arprot  : 3'b0;
	
	assign S1_ARVALID = (SM_mux_sread == S1_MUX) ? m_arvalid : 1'b0;
	assign S1_ARADDR  = (SM_mux_sread == S1_MUX) ? m_araddr  : 32'b0;
	assign S1_ARPROT  = (SM_mux_sread == S1_MUX) ? m_arprot  : 3'b0;
	
	assign m_arready  = (SM_mux_sread == S0_MUX) ? S0_ARREADY :
						(SM_mux_sread == S1_MUX) ? S1_ARREADY : 1'b0;
	
	
	// READ DATA <- SLAVE
	assign m_rdata = (SM_mux_sread == S0_MUX) ? S0_RDATA :
					 (SM_mux_sread == S1_MUX) ? S1_RDATA : 32'h0;
	assign m_rresp = (SM_mux_sread == S0_MUX) ? S0_RRESP :
					 (SM_mux_sread == S1_MUX) ? S1_RRESP : 2'b0;
	assign m_rvalid= (SM_mux_sread == S0_MUX) ? S0_RVALID:
					 (SM_mux_sread == S1_MUX) ? S1_RVALID: 1'b0;
	
	assign S0_RREADY= (SM_mux_sread == S0_MUX) ? m_rready : 1'b0;
	assign S1_RREADY= (SM_mux_sread == S1_MUX) ? m_rready : 1'b0;

	/**
	//! WARNING: this is a really shitty way of doing things.

	- In reality we would need something like round-robin scheduling or priority management.
	- In our case we simply give a fixed priority to one of them, which might starve the other.

	TODO:
	- Implement arbitration
	- Implement the actual handshake in between (raddr storage etc..)
	*/

endmodule