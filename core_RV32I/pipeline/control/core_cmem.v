`timescale 1ns/10ps
`include "define.vh"

module core_cmem (
	input CLK,
	input C_CMEM,
	input OPCODE
	input PC,
	input IMM,
	input REG_RDATA1, 				// To determine next address
	output reg [31:0] DMEM_ADDR, 	// calculated from immediate
	output reg ISLOADBS,
	output reg ISLOADHWS,
	output reg [3:0] STRB
);

// DETERMINE WHETHER LOAD / STORE
wire isload, isloadbs, isloadhws, isstore;
reg [3:0] STRB;
reg [31:0] DMEM_ARADDR;

assign isload = (OPCODE == `OPCODE_I_LOAD) ? 1 : 0;
assign isstore = (OPCODE == `OPCODE_S) ? 1 : 0;
assign dmem_araddr = (REG_RDATA1 + IMM)

// DETERMINE STROBE FOR LOAD
wire [7:0] load_bstrb, load_bu;
wire [15:0] load_hwstrb, load_hwu;

assign load_bstrb = (DMEM_ARADDR[1:0] == 2'b00) ? 4'b0001:
                (DMEM_ARADDR[1:0] == 2'b01) ? 4'b0010 :
                (DMEM_ARADDR[1:0] == 2'b10) ? 4'b0100 :
                4'b1000;
assign load_hwstrb = (DMEM_ARADDR[1:0] == 2'b00) ? 4'b0011 :
                4'b1100;

wire [3:0] load_strb;
assign load_strb = ((FUNCT3 == `FUNCT3_LB) | (FUNCT3 == `FUNCT3_LBU)) ? load_bstrb :
                        (FUNCT3 == `FUNCT3_LH) | (FUNCT3 == `FUNCT3_LHU) ? load_hwstrb:
                        4'b1111;

// DETERMINE STROBE FOR STORE
// Store instructions
wire [3:0] strb_b, strb_hw;

assign store_bstrb = (DMEM_AWADDR[1:0] == 2'b00) ? 4'b0001 :
				(DMEM_AWADDR[1:0] == 2'b01) ? 4'b0010 :
				(DMEM_AWADDR[1:0] == 2'b10) ? 4'b0100 :
				4'b1000;


assign store_hwstrb = (DMEM_AWADDR[1:0] == 2'b00) ? 4'b0011 :
				(DMEM_AWADDR[1:0] == 2'b01) ? 4'b0110 :
				4'b1100;

assign store_strb = (funct3 == `FUNCT3_SB) ? strb_b :
				(funct3 == `FUNCT3_SH) ? strb_hw :
				4'b1111;

// OUTPUT RELEVANT STROBE SIGNAL
assign strb = (ISLOAD) ? load_strb :
			(ISSTORE) : store_strb :
			4'b0000;

// OUTPUT UNSIGNED / SIGNED CASE
assign isloadbs = (FUNCT3 == `FUNCT3_LB);
assign isloadhws = (FUNCT3 == `FUNCT3_LH);

always @(posedge CLK)
begin
	if (C_CMEM)
	begin
		DMEM_ARADDR <= dmem_araddr;
		ISLOADBS <= isloadbs;
		ISLOADHWS <= isloadhws;
		STRB <= strb;
	end
end

endmodule

/**
- Gets the load/store opcode and FUNCT3
- 
ARGUMENTS
- FUNCT3
- PC, IMMEDIATE (to get the right offset): This way we can shift the registers and strobe everything at the memory axi bus controller
- C_ISLOAD, C_ISSTORE -> Used to determine the 
- REG_RDATA1, REG_RDATA2
	- In case of a LOAD: Used to set the strobe signals  (1100, 0110, 1000, 0100, ..)
	- In case of s STORE: Used to set the strobe signals (1100, 0110, 1000, 0100, ..)

IN OTHER MODUELS
- If store: get the data from reg2 -> store
- If load: get the data from load -> load into readreg
OTHER
- (OPCODE DRIVES THIS UNIT FROM CENTRAL CONTROL)
- 
*/