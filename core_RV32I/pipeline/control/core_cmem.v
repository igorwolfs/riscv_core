`timescale 1ns/10ps
`include "define.vh"

module core_cmem (
	input 				CLK,
	input 				NRST,
	input				ISLOAD,
	input				ISSTORE,
	input [31:0]		PC,
	input [31:0] 		IMM,
	input [31:0]		REG_RDATA1, 	// To determine next address
	input [2:0]			FUNCT3,
	output [31:0] 		DMEM_ADDR, 		// Calculated from immediate
	output 				ISLOADBS,
	output 				ISLOADHWS,
	output [3:0]	 	STRB,
	input 				BUSY,
	input				DONE,
	input 				EXMEM_C_ISSTORE,
	input				EXMEM_C_ISLOAD,
	output reg 			ISSTORE_SS,
	output reg 			ISLOAD_SS
);

// DETERMINE WHETHER LOAD / STORE
wire isloadbs, isloadhws, isstore;

assign DMEM_ADDR = (REG_RDATA1 + IMM);

// DETERMINE STROBE FOR LOAD
wire [3:0] load_bstrb, load_hwstrb, load_strb;

assign load_bstrb = (DMEM_ADDR[1:0] == 2'b00) ? 4'b0001:
                (DMEM_ADDR[1:0] == 2'b01) ? 4'b0010 :
                (DMEM_ADDR[1:0] == 2'b10) ? 4'b0100 :
                4'b1000;

assign load_hwstrb = (DMEM_ADDR[1:0] == 2'b00) ? 4'b0011 :
                4'b1100;

assign load_strb = ((FUNCT3 == `FUNCT3_LB) | (FUNCT3 == `FUNCT3_LBU)) ? load_bstrb :
                        (FUNCT3 == `FUNCT3_LH) | (FUNCT3 == `FUNCT3_LHU) ? load_hwstrb:
                        4'b1111;

// DETERMINE STROBE FOR STORE
// Store instructions
wire [3:0] store_bstrb, store_hwstrb, store_strb;

assign store_bstrb = (DMEM_ADDR[1:0] == 2'b00) ? 4'b0001 :
				(DMEM_ADDR[1:0] == 2'b01) ? 4'b0010 :
				(DMEM_ADDR[1:0] == 2'b10) ? 4'b0100 :
				4'b1000;

assign store_hwstrb = (DMEM_ADDR[1:0] == 2'b00) ? 4'b0011 :
				(DMEM_ADDR[1:0] == 2'b01) ? 4'b0110 :
				4'b1100;

assign store_strb = (FUNCT3 == `FUNCT3_SB) ? store_bstrb :
				(FUNCT3 == `FUNCT3_SH) ? store_hwstrb :
				4'b1111;


// OUTPUT UNSIGNED / SIGNED CASE
assign isloadbs = (FUNCT3 == `FUNCT3_LB);
assign isloadhws = (FUNCT3 == `FUNCT3_LH);

assign STRB = (ISLOAD) ? load_strb :
				(ISSTORE) ? store_strb :
				4'b0000;

assign ISLOADBS = (ISLOAD) ? isloadbs :
				1'b0;

assign ISLOADHWS = (ISLOAD) ? isloadhws :
				1'b0;

//! NOTE: if this becomes a problem move it to the central register set
/**
The issue here is that this data comes from the idex register every cycle.
- The isstore and isload registers are exmem registers.
- The other registers are idex.
*/
/*
always @(posedge CLK)
begin
	if (!NRST)
	begin
		ISLOADBS <= 1'b0;
		ISLOADHWS <= 1'b0;
	end
	else if (ISLOAD)
	begin
		ISLOADBS <= isloadbs;
		ISLOADHWS <= isloadhws;
	end
	else if (ISSTORE)
	begin
		ISLOADBS <= 1'b0;
		ISLOADHWS <= 1'b0;
	end
	else;
		*/
	// begin
	// 	ISLOADBS <= 1'b0;
	// 	ISLOADHWS <= 1'b0;
	// 	STRB <= 4'b0000;
	// end
// end

/**
NOTE: this will enable the ISLOAD_SS for one cycle (since the BUSY asserts after one cycle of the ISLOAD_SS)
BUT:
- When the operation is finished and EXMEM_C_ISLOAD is still high it will keep storing and loading.
- So somehow we have to trigger it only once, and then have a DONE signal that stops it from triggering again or something
- Perhaps a DONE register that goes high when the instruction fetch is done
- And then resets on exmem_c_isload or something like that
*/

always @(*)
begin
	ISLOAD_SS = 1'b0;
	ISSTORE_SS = 1'b0;
	if (!NRST);
	else if (EXMEM_C_ISLOAD & !BUSY & !DONE)
	begin
		ISLOAD_SS = 1'b1;
	end
	else if (EXMEM_C_ISSTORE & !BUSY & !DONE)
	begin
		ISSTORE_SS = 1'b1;
	end
	else;
end

// * Create single cycle Load / Store signal for memory stages
// always @(posedge CLK)
// begin
// 	if (!NRST)
// 	begin
// 		ISLOAD_SS <= 1'b0;
// 	end
// 	else if (EXMEM_C_ISLOAD & !BUSY) // SS LATCH
// 	begin
// 		ISLOAD_SS <= 1'b1;
// 	end
// 	else
// 		ISLOAD_SS <= 1'b0;
// end

// always @(posedge CLK)
// begin
// 	if (!NRST)
// 	begin
// 		ISSTORE_SS <= 1'b0;
// 	end
// 	else if (EXMEM_C_ISSTORE & !BUSY) // SS LATCH
// 	begin
// 		ISSTORE_SS <= 1'b1;
// 	end
// 	else
// 		ISSTORE_SS <= 1'b0;
// end

endmodule
