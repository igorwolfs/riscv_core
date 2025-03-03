# neorv32_package
Contains all kinds of architectural definitions, constants, ..

## bus_rq_t
- addr, data, ben, stb, rw, src, priv, debug, amo, amoop
- fence


## bus_rsp_t
- data
- ack
- err


# neorv32_top
- Contains a bunch of parameters like
	- IO_GPIO_NUM
	- IO_UART0_EN
	- IO_UART1_RX_FIFO
	- ...

## UART peripheral definition
- Enablable in neorv32_top.vhd
- uart0_txd_o, uart0_rxd_i, uart0_rtsn_o, uart0_ctsn_i 
	- internal signals present in top-module
- cond_sel_string_f(IO_UART0_EN,               "UART0 ",      "")
	- Used to show neorv-configuration on startup
- generating the neorv32.neorv32_uart entity when IO_UART0_EN is enabled
	- Module has SIM_MODE_EN
