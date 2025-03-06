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
	output [3:0]	C_WB_CODE,
	
	// *** REGISTER SIGNALS
	output 			C_REG_AWVALID,
	output [4:0] 	REG_ARADDR1, // Which read register 1 to use
	output [4:0] 	REG_ARADDR2, // Which read register 2 to use
	output [4:0] 	REG_AWADDR,  // Which register to write to
	input [31:0]	REG_RDATA1,
	input [31:0]	REG_RDATA2,

	// *** GENERAL
	output [31:0]	IMM,
	// *** ALU SIGNALS
	output 			C_ALU,
	output [3:0]	OPCODE_ALU,
	output			IS_IMM, 	// Shows whether its an immediate instruction or not => Used by alu when selecting REG2 vs immediate
	// *** MEMORY SIGNALS
	output [31:0] 	DMEM_ADDR, // Determines load / store address
	output			C_DOLOAD,
	output			ISLOADBS,
	output			ISLOADHWS,
	output			C_DOSTORE,
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
	input 			HOST_AXI_BVALID,
	input			HOST_AXI_BREADY
);

	// MEMORY SIGNALS
	wire isload, isloadbs, isloadhws, isstore;

	// DECODER SIGNALS
	wire [6:0] 	opcode;
	wire [2:0] 	funct3;
	wire [6:0] 	funct7;
	// BRANCHING SIGNALS
	wire 		take_branch;

	// CONTROL SIGNALS
	wire c_decode, c_cmem, c_branch;

	core_idecode core_idecode_inst (
		.CLK(CLK),
		.NRST(NRST),
		.INSTRUCTION(INSTRUCTION),
		.C_DECODE(c_decode),
		.OPCODE(opcode),
		.FUNCT3(funct3),
		.FUNCT7(funct7),
		.IMM(IMM),
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
        .OPCODE_ALU(OPCODE_ALU)
    );

	core_cbranch core_cbranch_inst (
		.NRST(NRST),
		.CLK(CLK),
		.C_BRANCH(c_branch),
		.FUNCT3(funct3),
		.REG_RDATA1(REG_RDATA1),
		.REG_RDATA2(REG_RDATA2),
		.TAKE_BRANCH(take_branch)
	);

	core_cmem core_cmem_inst (
		.CLK(CLK),
		.C_CMEM(c_cmem),
		.OPCODE(opcode),
		.PC(PC),
		.IMM(imm),
		.REG_RDATA1(REG_RDATA1),
		.DMEM_ADDR(DMEM_ADDR),
		.ISLOAD(isload),
		.ISLOADBS(isloadbs),
		.ISLOADHWS(isloadhws),
		.ISSTORE(isstore),
		.STRB(STRB)
	);

	// ==============================================
	// CENTRAL LOGIC
	// ==============================================
	localparam S_IFETCH 		= 0;
	localparam S_IDECODE 		= 1; // Normally the register read should be done here as well
	localparam S_EXEC	  	 	= 2;
	localparam S_MEM 			= 3;
	localparam S_WB 			= 4;

	reg [3:0] state_machine;
	wire [3:0] next_state;

	IMM = (C_ALU & (opcode == `OPCODE_I_ALU)) ? alu_imm : imm;
	// ASSIGN NEXT STATE DEPENDING ON WHETHER S_IFETCH WAS SUCCESFULL
	always @(*)
	begin
		C_INSTR_FETCH = 1'b0;
		C_ALU = 1'b0;
		C_REG_AWVALID = 1'b0;
		c_cmem = 1'b0;
		C_DOSTORE = 1'b0;
		C_DOLOAD = 1'b0;
		c_branch = 1'b0;
		C_PC_UPDATE = 1'b0;
		C_WB_CODE = 4'b0;
		case (state_machine)
			S_IFETCH:
			begin
				C_INSTR_FETCH = 1'b1; // Enable instruction fetch
				// Instruction fetch
				if (IMEM_AXI_RVALID & IMEM_AXI_RREADY)
				begin
					C_INSTR_FETCH = 1'b0;
					next_state = S_IDECODE;
				end
			end
			S_IDECODE:
				begin
				// Register read and decode stage (takes 1 cycle, always)
				case (opcode)
					`OPCODE_J_JAL, `OPCODE_I_JALR, `OPCODE_U_LUI, `OPCODE_U_AUIPC:
						// When dealing with a JAL(R), lui, auipc instructions, there's only immediate extraction / regread / PC_incr and a regwrite left -> so jump directly to S_WB
						next_state = S_WB;
					default:
						next_state = S_EXEC;
				endcase
				end
			S_EXEC:
				// Depending on the type of instruction we'll have to do one (or more) of various things
				// Operations with register operands
				// Branching calculations
				// Create increment for PC (should be known here)
				begin
				case (opcode)
					`OPCODE_R:
						begin
						next_state = S_WB;
						C_ALU = 1'b1;
						end

					`OPCODE_I_ALU:
						begin
						next_state = S_WB; // Go to next state, by default immediate is not used
						C_ALU = 1'b1;
						end

					`OPCODE_I_LOAD, `OPCODE_S:
						begin
						next_state = S_MEM;
						c_cmem = 1'b1; // Latches the memory control signal
						end

					`OPCODE_B:
						begin
						next_state = S_WB;
						c_branch = 1'b1;
						end
					endcase
				end
			S_MEM:
			case (opcode)
				// Memory control signals (raddr, load, loadbs, loadhws, store, strb) are latched
				`OPCODE_I_LOAD:
					begin
						C_DOLOAD = 1'b1;
						if (HOST_AXI_RREADY & HOST_AXI_RVALID) // DMEM AXI STALL
							next_state = S_WB;
						else
							next_state = S_MEM;
					end
				`OPCODE_I_STORE:
					begin
						C_DOSTORE = 1'b1;
						if (HOST_AXI_BVALID & HSOT_AXI_BREADY) // DMEM AXI STALL
							next_state = S_WB;
						else
							next_state = S_MEM;
					end
			endcase
			S_WB:
			begin
				next_state = S_IFETCH;
				C_PC_UPDATE = 1'b1;
				case (opcode)
					`OPCODE_R, OPCODE_I_ALU:
						begin
							C_WB_CODE = `WB_CODE_ALU;
							C_REG_AWVALID = 1'b1;
						end
					`OPCODE_B:
						begin
							if (take_branch)
								C_WB_CODE = `WB_CODE_BRANCH;
							else;
						end
					`OPCODE_I_LOAD:
						begin
							C_WB_CODE = `WB_CODE_LOAD;
							C_REG_AWVALID = 1'b1;
						end
					`OPCODE_J_JAL:
						begin
							C_WB_CODE = `WB_CODE_JAL;
							C_REG_AWVALID = 1'b1;
						end
						
					`OPCODE_I_JALR:
						begin
							C_WB_CODE = `WB_CODE_JALR;
							C_REG_AWVALID = 1'b1;
							// FLAG TO INDICATE RS1+IMM -> PC instead of IMM += PC
						end
					`OPCODE_U_LUI:
						begin
							C_WB_CODE = `WB_CODE_LUI;
							C_REG_AWVALID = 1'b1;
							// Make sure the imm is written here
						end
					`OPCODE_U_AUIPC:
						begin
							C_WB_CODE = `WB_CODE_AUIPC;
							C_REG_AWVALID = 1'b1;
							// Make sure the imm + PC is written here
						end
					`OPCODE_S:;
				endcase
			end
		endcase
	end

	always @(posedge CLK)
	begin
		if (!NRST)
			state_machine <= S_IFETCH
		else
			state_machine <= next_state;
	end


endmodule


/** EXEC **
IF BRANCH INSTRUCTION
- Check branching condition
- Make sure the brancher module says the branch was (in)valid
- go to S_WB (where you increment pc)
IF ALU INSTRUCTION
- Drive ALU signals with register values
- go to S_WB (where you store alu_o into register + default-increment pc)
if LOAD/STORE
- if load/store -> go to S_MEM
if JAL 
- if jal -> go to S_WB (where you write to rd + increment PC)
if JALR
- if jalr -> go to S_WB (where you write to rd, increment PC with register value)
*/
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
// !NOTE:
- Decode the read / write indices combinatorially, and latch them.
- If you need for example the write signal for a certain instruction what is done is
	- It is usually carried along hte pipeline through the states in a register.
*/

/**
//! NOTE:
- Normally all pipelining registers are kept centralized
	- So they can be easily passed along through pipelined stages if necessary
	- Make sure to do that later once you've actually implemented the FSM with latches in ALU / BRANCHING / MEMORY modules
- NORMALLY all modules are in fact purely combinatorial
	- So make sure to bring all latched registers inside the instruction decoding outside of it
	- Keep them somewhere central
- For now latch the registers on the outside
	- Keep the complex pipelining-register logic for a later stage, make sure your FSM works first
*/

/**
// ? Can we directly jump from the IFETCH stage to the WD stage for JALR / JAL INSTRUCTIONS?
*/