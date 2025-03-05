`timescale 1ns/10ps
`include "define.vh"

/**
TOP control module must
- Keep track of the current state we're in
- Drive signals for each cpu part to do its thing
	- instruction fetch
	- instruction decode
	- ALU calculation / load or store instruction
	- PC increment
*/

module core_control (
	input 			CLK, NRST,
	// *** INSTRUCTION FETCH SIGNALS
	input [31:0] 	INSTRUCTION,
	input 			PC,
	output 			C_INSTR_FETCH,
	output 			C_PC_UPDATE,
	// *** REGISTER SIGNALS
	output 			REG_AWVALID,
	output [4:0] 	REG_ARADDR1, // Which read register 1 to use
	output [4:0] 	REG_ARADDR2, // Which read register 2 to use
	output [4:0] 	REG_AWADDR,  // Which register to write to
	input [31:0]	REG_RDATA1,
	input [31:0]	REG_RDATA2,
	// *** ALU SIGNALS
	output 			OPCODE_ALU,
	output [31:0]	ALU_O,
	output			IS_IMM, 	// Shows whether its an immediate instruction or not => Used by alu when selecting REG2 vs immediate
	// *** MEMORY SIGNALS
	output [31:0] 	DMEM_ARADDR, // Determines load / store address
	output			ISLOAD,
	output			ISLOADBS,
	output			ISLOADHWS,
	output			ISSTORE,
	output [3:0]	STRB,
	// *** INSTRUCTION MEMORY AXI SIGNALS
	// And for read valid
	input			IMEM_AXI_RVALID,
	input			IMEM_AXI_RREADY,
	// *** DATA MEMORY AXI SIGNALS
	// Write valid
	input 			HOST_AXI_RVALID,
	input			HOST_AXI_RREADY,
	// Read valid
	input 			HOST_AXI_BVALID
);

	// MEMORY SIGNALS
	wire isload, isloadbs, isloadhws, isstore;

	// DECODER SIGNALS
	wire [6:0] 	opcode;
	wire [2:0] 	funct3;
	wire [6:0] 	funct7;
	wire [31:0] imm;
	// BRANCHING SIGNALS
	wire 		take_branch;

	// CONTROL SIGNALS
	wire c_decode;

	core_idecode core_idecode_inst (
		.CLK(CLK),
		.NRST(NRST),
		.INSTRUCTION(INSTRUCTION),
		.C_DECODE(c_decode),
		.OPCODE(opcode),
		.FUNCT3(funct3),
		.FUNCT7(funct7),
		.IMM(imm),
		.IS_IMM(IS_IMM),
		.REG_ARADDR1(REG_ARADDR1),
		.REG_ARADDR2(REG_ARADDR2),
		.REG_AWADDR(REG_AWADDR)
	);

	core_calu core_calu_inst (
        .OPCODE(opcode),
        .FUNCT3(funct3),
        .FUNCT7(funct7),
        .IMM(imm),
        .ALU_IMM(alu_imm),
        .OPCODE_ALU(OPCODE_ALU),
        .REG_ARADDR1_ALU(reg_araddr1_alu),
        .REG_ARADDR2_ALU(reg_araddr2_alu),
        .OPCODE_ALU(opcode_alu)
    );

	core_cbranch core_cbranch_inst (
		.FUNCT3(funct3),
		.REG_RDATA1(REG_RDATA1),
		.REG_RDATA2(REG_RDATA2),
		.TAKE_BRANCH(take_branch)
	);

	core_cmem core_cmem_inst (
		.OPCODE(opcode),
		.PC(PC),
		.IMM(imm),
		.REG_RDATA1(REG_RDATA1),
		.DMEM_ARADDR(DMEM_ARADDR),
		.ISLOAD(isload),
		.ISLOADBS(isloadbs),
		.ISLOADHWS(isloadhws),
		.ISSTORE(isstore),
		.STRB(STRB)
	);

	// ==============================================
	// CENTRAL LOGIC
	// ==============================================
	localparam S_IFETCH 	= 0;
	localparam S_IDECODE 	= 1;
	localparam S_EXEC 		= 2;
	localparam S_MEM 		= 3;
	localparam S_WB 		= 4;

	reg state_machine;
	wire next_state;


	// ASSIGN NEXT STATE DEPENDING ON WHETHER S_IFETCH WAS SUCCESFULL
	always @(*)
	begin
		if (!NRST)
		begin
			state_machine <= S_IFETCH;
		end
		else
			case (state_machine)
				S_IFETCH:
				begin
					if (AXI_RVALID & AXI_RREADY)
						next_state = S_IDECODE;
						// S_INSTR_FETCH -> enable
				end
				S_IDECODE:
					next_state = S_EXEC;
				S_EXEC:
				S_MEM:

				S_WB:

			endcase;
	end



endmodule


// EXEC
// - Wait for 1 clock cycle after read/write were set -> read appropriate signals from registers (wait 1 cycle for them to stabilize)
// 
// - Do branch check
// - if load/store -> go to S_MEM

/**
FUNCTIONALITY
- contains all control submodules
- Supposed to keep track of the current cpu state and used the submodule returns accordingly
	- Drives the ALU (register value outputs + alu write enable + alu_read)
	- Initializes / Checks whether the instruction fetch is done
	- Initializes / Checks whether the memory load / store is done
INPUTS:
- instruction
*/

/**
INSIDE THE CORE CONTROL
- Make sure to select a different the ALU-immediate if we're dealing with an ALU instruction, and output that immediate
- Make sure to determine whether the instruction is an ALU instruction
- Add a jump-handler instruction
- Check whether a branch or jump is being taken, and increment the program counter accordingly
- Generate the required core_mem signals depending on the core_cmem control signals and the machine state

-> OR maybe just put all this control logic INSIDE the core instead of in a package where a million signals go in and out?
-> It will lead to a LOT of signals in one though.
*/

/**
// !NOTE:
- It makes more sense to have the state machine centralized and propagate signals from the state machine
	- IF: you can set your modules as separate states
	- BECAUSE: then you don't propagate the states, you just drive all your pipelin-control signals from your central state machine inside your control circuitry.
*/