# Pipelining
## ALU R instruction
0. Instruction fetch
	- Get AXI_RDATA
0->1
- Instruction-latched (INSTRUCTION <= AXI_RDATA)

1. Instruction decode:
	- Combinatorial
		- reg1_read, reg2_read
1->2
- reg1_read, reg2_read latched in register for next
- funct3, funct7, opcode (needed only in next stage)
- regwrite_addr (needed at wb-stage)

2. EXEC
	- Combinatorial 
		- calu val decode from funct, imm, opcode
		- Combinatorial setting alui1, alui2
2->4
- alu-enable to latch alu_out (needed only in next stage)

4. WB
	- combinatorial
		- set pc_increment
		- set value to be written to register
4->0
- regwrite
- pc_increment

### ISSUES:
- Register write value is latched in 1->2 but only used in 4->0
	- It should be latched until the pipeline's done

## ALU I instruction
0. Instruction fetch
	- Get AXI_RDATA
0->1
- Instruction-latched (INSTRUCTION <= AXI_RDATA)

1. Instruction decode:
	- Combinatorial
		- reg1_read, reg2_read
1->2
- reg1_read, reg2_read latched in register for next
- Immediate, funct3, funct7, opcode
- regwrite_addr (needed at wb-stage)

2. EXEC
	- Combinatorial 
		- calu val decode from funct, imm, opcode
		- Combinatorial setting alui1, alui2
2->4
- alu-enable to latch alu_out

4. WB
	- combinatorial
		- set pc_increment
		- set value to be written to register
4->0
- regwrite
- pc_increment

### ISSUES:
- Register write value is latched in 1->2 but only used in 4->0
	- It should be latched until the pipeline's done

## Load instruction
0. Instruction fetch
	- Get AXI_RDATA
0->1
- Instruction-latched, FUNCT3, FUNCT7 (only for next)

1. Instruction decode:
	- Combinatorial
		- reg1_read, reg2_read
1->2
- reg1_read, reg2_read latched in register for next
- Immediate funct3, funct7, regwrite_addr, opcode
2. EXEC
	- Combinatorial
		- determine dmem_araddr, loadbs, loadhws, strb

2->3
- dmem_araddr, loadbs, loadhws, strb
- reg1_read, reg2_read: stored until memory stage from execution stage
	- Possible hazards here when reg1_write / reg2_write didn't yet happen

3. MEM
	- Combinatorially: 
		- set dmem_addr to axxi_awaddr
		- set strb
3->4:
- nothing

4. WB
- 

4->0
- pc_increment (default value)


## Store instruction
0. Instruction fetch
	- Get AXI_RDATA
0->1
- Instruction-latched, FUNCT3, FUNCT7 (only for next)

1. Instruction decode:
	- Combinatorial
		- reg1_read, reg2_read
1->2
- reg1_read, reg2_read latched in register for next
- Immediate funct3, funct7, regwrite_addr, opcode
2. EXEC
	- Combinatorial
		- determine dmem_araddr, loadbs, loadhws, strb

2->3
- dmem_araddr, loadbs, loadhws, strb
- reg1_read, reg2_read: stored until memory stage from execution stage
	- Possible hazards here when reg1_write didn't yet happen

3. MEM
	- Combinatorially: 
		- set dmem_addr to axxi_awaddr
		- set strb
3->4:
- nothing

4. WB
- 

4->0
- pc_increment (default value)
- 

## Branch
0. Instruction fetch
	- Get AXI_RDATA
0->1
- Instruction-latched (INSTRUCTION <= AXI_RDATA)

1. Instruction decode:
	- Combinatorial
		- reg1_read, reg2_read
1->2
- reg1_read, reg2_read latched in register for next
- funct3, funct7, opcode (needed only in next stage)
- immediate needs to be latched until WB stage

2. EXEC
	- Combinatorial 
		- calu val decode from funct, imm, opcode
		- Combinatorial setting alui1, alui2
2->4
- alu-enable to latch alu_out (needed only in next stage)

4. WB
	- combinatorial
		- set pc_increment
		- set value to be written to register
4->0
- regwrite
- pc_increment

## JAL(R)
0. Instruction fetch

1. Instruction decode
1->4: 
- rdata1 latched
- waddr latched
- immediate latched

4. Branch WB
4->0
DEPENDING ON INSTRUCTION
- JAL: immediate added to PC
- JALR: immediate + reg_rdata1 set equal to PC
- PC+4 written to regwrite 

### ISSUES:
- 2->3: all these things are latched only for a single clock cycle, but the actual memory operation takes more time.
- 1->2: reg_rdata2 is not latched until 3, but it is the data that is written to data memory using the strobe. This data should be latched somewhere.


# IDEA
- While the registers are still dispersed everywhere
	- Keep the instruction and everything else latched until the next instruction comes through the axi bus
	- Later centralize everything in multiple registers once you start pipelining.
- JAL(R) issues
	- When a JAL(R) instruction comes, the PC can't continue where it's at, It can
		- Stall the pipeline
		- Add an extra data-path directly decoding the JAL(R) immediate and adding it to the PC in the same clock-cycle
So for now:
- Try to clock the CPU as quickly as possible and check the result.
### Centralize the registers inside the control unit 

## Create a hazard detection (HDU)
Control Hazards:
- Implement flushing in case of JAL(R) mechanisms.
- Implement flushing in case of a taken branch.

Data Hazards
- Implement checks on reads and writes of the pipeline
- Implement checks on loads into register
	- Stall when an instruction is trying to read from a register something that is still being stored into the register.

Insert a "bubble" in the pipeline.

### Essential signals
- Stall
- Flush

## Outputs
- What is the immediate output for? When is it used?
	- PC_NEXT (So MEMWB_PC needed here)
	- reg_wdata (So MEMWB_PC needed here)
	- alu increments (so IDEX_IMM needed here)
# ISSUES

- How do I register in the beginning which stages need to be skipped?
	- Maybe having some register that, in the decode-stage, registers the future signals to be enabled (c_alu, c_reg)
- Once I register this I can simply pass the elements from one to another.


It seems like the pipeline control unit is in fact what we need.
But we seem to just need to take the control signals generated there, and store them in intermediate registers to be carried instead of determining everthing baseed based on the next or current state

## Compile check
It seems like most signals at the moment were assigned correctly.

Let's check whether it compiles

## Basic simulation attempt


## Hazard detection unit