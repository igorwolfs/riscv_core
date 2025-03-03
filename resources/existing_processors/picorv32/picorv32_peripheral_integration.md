# simpleuart
## Signals
### System-signals
- clk, resetn

### Serial signals
- ser_tx, ser_rx

### Divider
- div_we
- div_di (sets divider)
- div_do (shows divider configuration)
	- Split into 4-bytes, separately writable.

### Data
- dat_we, dat_re, dat_di, dat_do, dat_wait


## Design
### Divider synchronous block
- Takes in the reg_div_di and stores it in its own cfg_divider-byte depending on the strobe-signal.

### Receive synchronous block
Combines both the state and the data transmission handling using a counter.
- Reset statement
- Manages the state
	- Receive state 0: Waits for ser_rx to be set low -> switches to state 1
	- Receive state 1: Means it got the start bit
		- it counts 2 * the divider
		- When it's done counting -> moves to state 2
	- Receive state 2..9: 
		- counts 8 divider (recv_divcnt) increments
		- updates the 8-bit recv_pattern-register
	- Receive state 10:
		- indicates buffer valid for 1 clock-cycle
		- Sets recv_state back to 0 in case of 

### Receive send synchronous block
- last if-else, shifts the send_pattern each time -> send_pattern = (1, send_pattern << 1)
- First if-else: sends dummy variable
- second if-else: initializes the send-pattern on reg_dat_we
- send_bitcnt: keeps track of the number of bits that were sent. 
	- (10 by default -> being subctracted as the uart_data is being sent)



## Attachment to the CPU-core

```verilog
	wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
	wire [31:0] simpleuart_reg_div_do;

	wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
	wire [31:0] simpleuart_reg_dat_do;
	wire        simpleuart_reg_dat_wait;

	assign mem_ready = (iomem_valid && iomem_ready) || spimem_ready || ram_ready || spimemio_cfgreg_sel ||
			simpleuart_reg_div_sel || (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait);

	assign mem_rdata = (iomem_valid && iomem_ready) ? iomem_rdata : spimem_ready ? spimem_rdata : ram_ready ? ram_rdata :
			spimemio_cfgreg_sel ? spimemio_cfgreg_do : simpleuart_reg_div_sel ? simpleuart_reg_div_do :
			simpleuart_reg_dat_sel ? simpleuart_reg_dat_do : 32'h 0000_0000;
```

### div write / read
- Write to memory address 0200_0004
- Reading this address will give: simpleuart_reg_div_do

### data write / read
- Write to memory addres 0200_0008
- set the mem_wstrb-signal
	- This enables the memory data write
- mem_ready signal is disabled if dat_wait is enabled
	- mem_wstrb: Enabled in the memory interface