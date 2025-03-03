# neorv32_uart

## Signals
### System
- clk_i, rstn_i

### Bus
- bus_req_i
- bus_resp_o

### clkgen
- clkgen_en_o
- clkgen_i

### Data
- tx-serial-data
- rx-serial-data
- rts
- cts

### irq
- irq_rx_o
- irq_tx_o 

Trigger interrupts on empty / half / full .. various conditions set in registers.

## Architecture
### bus_access - process
defined in neorv32_package.vhd

Manages read / writes of registers.
- bus_req_i
- bus_rsp_o

The bus_rsp_o