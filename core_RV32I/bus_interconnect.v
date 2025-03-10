
`timescale 1ns/10ps

`include "axi_defines.vh"

module bus_interconnect #(
	parameter AXI_DWIDTH = 32,
	parameter AXI_AWIDTH = 32,
	parameter S0_EN = 1'b1,
	parameter S1_EN = 1'b1,
	parameter S2_EN = 1'b1,
	parameter ADDR_S0_START = 32'h00000000,
	parameter ADDR_S0_END   = 32'h3FFFFFFF,
	parameter ADDR_S1_START = 32'h40000000,
	parameter ADDR_S1_END   = 32'h4000000F,
	parameter ADDR_S2_START = 32'hF0000000, // END SIM / WRITE TO FILE
	parameter ADDR_S2_END 	= 32'hF0000007
)(
	input wire          ACLK,
	input wire          ARESETN,

	// HOST interface
    `AXI_MASTER_PORTS(H, AXI_AWIDTH, AXI_DWIDTH),

    // IMEM interface
    `AXI_MASTER_PORTS(IMEM, AXI_AWIDTH, AXI_DWIDTH),

    // Slave 0 interface
    `AXI_SLAVE_PORTS(0, AXI_AWIDTH, AXI_DWIDTH),

    // Slave 1 interface
	`AXI_SLAVE_PORTS(1, AXI_AWIDTH, AXI_DWIDTH),

    // Slave 2 interface
	`AXI_SLAVE_PORTS(2, AXI_AWIDTH, AXI_DWIDTH)
);


	// ===========================================
	// BUS MUXING
	// ===========================================

	// *** MUX master states ***
	localparam H_MUX = 1'b0;
	localparam IMEM_MUX = 1'b1;
	
	// *** MUX Devices ***
	localparam S0_MUX = 2'h00;
	localparam S1_MUX = 2'h1;
	localparam S2_MUX = 2'h2;

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



    // -------------------------------------------
    // WRITE-Address & Data MUX
    // -------------------------------------------
    reg        SM_mux_mwrite;  // Which master is currently writing?
    reg  [1:0] SM_mux_swrite;  // Which slave is selected for writes?

    always @(posedge ACLK) begin
        if (!ARESETN) 
		begin
            SM_mux_mwrite <= H_MUX;
            SM_mux_swrite <= S0_MUX;
        end 
        else 
			begin
            // Priority: If Host sends AWVALID+WVALID (and accepted), latch that
            if ((H_AWREADY & H_WVALID & H_AWVALID)) 
			begin
                SM_mux_mwrite <= H_MUX;
                // Decide which slave, checking Sx_EN
                if (`IN_RANGE_EN(0, H_AWADDR))
                    SM_mux_swrite <= S0_MUX;
                else if (`IN_RANGE_EN(1, H_AWADDR))
                    SM_mux_swrite <= S1_MUX;
                else if (`IN_RANGE_EN(2, H_AWADDR))
                    SM_mux_swrite <= S2_MUX;
                else
                    SM_mux_swrite <= S0_MUX; // default fallback
            end
            // Else if IMEM does the same
            else if ((IMEM_AWREADY & IMEM_WVALID & IMEM_AWVALID)) 
			begin
                SM_mux_mwrite <= IMEM_MUX;
                if (`IN_RANGE_EN(0, IMEM_AWADDR))
                    SM_mux_swrite <= S0_MUX;
                else if (`IN_RANGE_EN(1, IMEM_AWADDR))
                    SM_mux_swrite <= S1_MUX;
                else if (`IN_RANGE_EN(2, IMEM_AWADDR))
                    SM_mux_swrite <= S2_MUX;
                else
                    SM_mux_swrite <= S0_MUX; // default fallback
            end 
            else 
			begin
                // Default to Host
                SM_mux_mwrite <= H_MUX;
                // Re-decode address from Host as default
                if (`IN_RANGE_EN(0, H_AWADDR))
                    SM_mux_swrite <= S0_MUX;
                else if (`IN_RANGE_EN(1, H_AWADDR))
                    SM_mux_swrite <= S1_MUX;
                else if (`IN_RANGE_EN(2, H_AWADDR))
                    SM_mux_swrite <= S2_MUX;
                else
                    SM_mux_swrite <= S0_MUX;
            end
        end
    end

    // -------------------------------------------
    // READ-Address & Data MUX
    // -------------------------------------------
    reg        SM_mux_mread;   // Which master is reading?
    reg  [1:0] SM_mux_sread;   // Which slave is selected for reads?

    always @(posedge ACLK) begin
        if (!ARESETN) 
		begin
            SM_mux_mread <= IMEM_MUX; 
            SM_mux_sread <= S0_MUX;
        end 
        else 
			begin
            // If IMEM issues ARVALID + is ready
            if (IMEM_ARVALID & IMEM_RREADY) 
			begin
                SM_mux_mread <= IMEM_MUX;
                // Slave selection
                if (`IN_RANGE_EN(0, IMEM_ARADDR))
                    SM_mux_sread <= S0_MUX;
                else if (`IN_RANGE_EN(1,  IMEM_ARADDR))
                    SM_mux_sread <= S1_MUX;
                else if (`IN_RANGE_EN(2,  IMEM_ARADDR))
                    SM_mux_sread <= S2_MUX;
                else
                    SM_mux_sread <= S0_MUX;
            end
            // Else if Host does ARVALID + is ready
            else if (H_ARVALID & H_RREADY) 
			begin
                SM_mux_mread <= H_MUX;
                if (`IN_RANGE_EN(0,  H_ARADDR))
                    SM_mux_sread <= S0_MUX;
                else if (`IN_RANGE_EN(1,  H_ARADDR))
                    SM_mux_sread <= S1_MUX;
                else if (`IN_RANGE_EN(2,  H_ARADDR))
                    SM_mux_sread <= S2_MUX;
                else
                    SM_mux_sread <= S0_MUX;
            end
            else 
			begin
                // Default to IMEM
                SM_mux_mread <= IMEM_MUX;
                if (`IN_RANGE_EN(0, IMEM_ARADDR))
                    SM_mux_sread <= S0_MUX;
                else if (`IN_RANGE_EN(1,  IMEM_ARADDR))
                    SM_mux_sread <= S1_MUX;
                else if (`IN_RANGE_EN(2,  IMEM_ARADDR))
                    SM_mux_sread <= S2_MUX;
                else
                    SM_mux_sread <= S0_MUX;
            end
        end
    end

    // ------------------------------------------
    // Master MUX: Combine HOST / IMEM -> “m_” signals
    // ------------------------------------------
    // Write address channel
    assign m_awaddr  = (SM_mux_mwrite == H_MUX)   ? H_AWADDR  : IMEM_AWADDR;
    assign m_awprot  = (SM_mux_mwrite == H_MUX)   ? H_AWPROT  : IMEM_AWPROT;
    assign m_awvalid = (SM_mux_mwrite == H_MUX)   ? H_AWVALID : IMEM_AWVALID;

    // Write data channel
    assign m_wdata   = (SM_mux_mwrite == H_MUX)   ? H_WDATA   : IMEM_WDATA;
    assign m_wstrb   = (SM_mux_mwrite == H_MUX)   ? H_WSTRB   : IMEM_WSTRB;
    assign m_wvalid  = (SM_mux_mwrite == H_MUX)   ? H_WVALID  : IMEM_WVALID;

    // Read address channel
    assign m_araddr  = (SM_mux_mread == H_MUX)    ? H_ARADDR  : IMEM_ARADDR;
    assign m_arprot  = (SM_mux_mread == H_MUX)    ? H_ARPROT  : IMEM_ARPROT;
    assign m_arvalid = (SM_mux_mread == H_MUX)    ? H_ARVALID : IMEM_ARVALID;

    // Read data channel
    assign m_rready  = (SM_mux_mread == H_MUX)    ? H_RREADY  : IMEM_RREADY;

    // ------------------------------------------
    // SLAVE-Side MUXing: Write Address
    // ------------------------------------------

	// Generating master assignments
	assign m_awready = (SM_mux_swrite == S0_MUX && S0_EN) ? S0_AWREADY :
                       (SM_mux_swrite == S1_MUX && S1_EN) ? S1_AWREADY :
                       (SM_mux_swrite == S2_MUX && S2_EN) ? S2_AWREADY :
                                                            1'b0;

    assign m_wready  = (SM_mux_swrite == S0_MUX && S0_EN) ? S0_WREADY :
                       (SM_mux_swrite == S1_MUX && S1_EN) ? S1_WREADY :
                       (SM_mux_swrite == S2_MUX && S2_EN) ? S2_WREADY :
                                                            1'b0;

    // ------------------------------------------
    // WRITE Response (Slave->Master)
    // ------------------------------------------
    assign m_bresp  = (SM_mux_swrite == S0_MUX && S0_EN) ? S0_BRESP  :
                      (SM_mux_swrite == S1_MUX && S1_EN) ? S1_BRESP  :
                      (SM_mux_swrite == S2_MUX && S2_EN) ? S2_BRESP  : 2'b00;


    assign m_bvalid = (SM_mux_swrite == S0_MUX && S0_EN) ? S0_BVALID :
                      (SM_mux_swrite == S1_MUX && S1_EN) ? S1_BVALID :
                      (SM_mux_swrite == S2_MUX && S2_EN) ? S2_BVALID : 1'b0;


    // ARREADY back to MUX
    assign m_arready = (SM_mux_sread == S0_MUX && S0_EN) ? S0_ARREADY :
                       (SM_mux_sread == S1_MUX && S1_EN) ? S1_ARREADY :
                       (SM_mux_sread == S2_MUX && S2_EN) ? S2_ARREADY :
                                                            1'b0;
    // ------------------------------------------
    // READ Data <- Slaves
    // ------------------------------------------
    assign m_rdata  = (SM_mux_sread == S0_MUX && S0_EN) ? S0_RDATA :
                      (SM_mux_sread == S1_MUX && S1_EN) ? S1_RDATA :
                      (SM_mux_sread == S2_MUX && S2_EN) ? S2_RDATA : 32'h0;

    assign m_rresp  = (SM_mux_sread == S0_MUX && S0_EN) ? S0_RRESP :
                      (SM_mux_sread == S1_MUX && S1_EN) ? S1_RRESP :
                      (SM_mux_sread == S2_MUX && S2_EN) ? S2_RRESP : 2'b00;

    assign m_rvalid = (SM_mux_sread == S0_MUX && S0_EN) ? S0_RVALID :
                      (SM_mux_sread == S1_MUX && S1_EN) ? S1_RVALID :
                      (SM_mux_sread == S2_MUX && S2_EN) ? S2_RVALID : 1'b0;

	assign m_bready = (SM_mux_mwrite == H_MUX) ? H_BREADY : IMEM_BREADY;


	// ------------------------------------------
    // Master MUX -> Response back to HOST/IMEM
    // ------------------------------------------

	`AXI_MASTER_GENERATE_BLOCK(H, AXI_DWIDTH)
	`AXI_MASTER_GENERATE_BLOCK(IMEM, AXI_DWIDTH)

    // ------------------------------------------
    // Slave MUX -> Response to S<slave_number> from m_
    // ------------------------------------------

	`AXI_SLAVE_GENERATE_BLOCK(0, AXI_AWIDTH, AXI_DWIDTH)
	`AXI_SLAVE_GENERATE_BLOCK(1, AXI_AWIDTH, AXI_DWIDTH)
	`AXI_SLAVE_GENERATE_BLOCK(2, AXI_AWIDTH, AXI_DWIDTH)				  

endmodule
	/**
	//! WARNING: this is a really shitty way of doing things.

	- In reality we would need something like round-robin scheduling or priority management.
	- In our case we simply give a fixed priority to one of them, which might starve the other.

	TODO:
	- Implement arbitration
	- Implement the actual handshake in between (raddr storage etc..)

	//! MAJOR ISSUE
	- If the mux was in H mode, and suddenly there is an imem request it will switch back to imem mode

	*/
