# Pipelining
## ALU instruction
0. Instruction fetch
	- Get AXI_RDATA
0->1
- Instruction-latched (INSTRUCTION <= AXI_RDATA)

1. Instruction decode:
	- Combinatorial
		- reg1_read, reg2_read
1->2
- reg1_read, reg2_read latched in register for next
- Immediate, funct3, funct7, regwrite_addr, opcode
	
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

## Store instruction
0. Instruction fetch
	- Get AXI_RDATA
0->1
- Instruction-latched (INSTRUCTION <= AXI_RDATA)

1. Instruction decode:
	- Combinatorial
		- reg1_read, reg2_read
1->2
- reg1_read, reg2_read latched in register for next
- Immediate, funct3, funct7, regwrite_addr, opcode

2. EXEC
	- Combinatorial
		- determine dmem_araddr, loadbs, loadhws, strb

2->3 
- Latch dmem_araddr, loadbs, loadhws, strb

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

## JAL(R)
0. Instructino fetch

1. Instruction decode

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
- Implement simple pipelining with flushing in case of branch / mechanisms 

# ISSUES