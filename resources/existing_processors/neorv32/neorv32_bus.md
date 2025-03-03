# neorv32_bus_io_switch
## Parameters
Is the bus that manages the memory access control to peripherals
- INREG_EN, OUTREG_EN
- DEV_SIZE: shows size of single IO device
	- Allocates a certain amount of memory for each device on the bus.

### Peripherals
- Protocol peripherals (IO_UART0_en, SPI (IO_SDI_EN / IO_SPI), )
- custom functions (CFS: custome function subsystem), WDT, DMA
- MEMORY: BOOTROM_EN, BOOTROM, 

**Enable parameter**
- Enables the peripheral -> saves in dev_en_list_c

**Base-parameter**
- Passes the Base-address -> saves in dev_base_list_c

## Signals / Outputs

**Contains an input parameter for each device**
- 

**signals**
- SYSTEM SIGNALS: clk_i, rstn_i signal
- HOST PORT SIGNALS: main_req_i, main_rsp_o
- DEVICE PORTS: dev_%02d_req_o (bus request type), dev_%02d_resp_i (bus response type)

## Request / Response handling

The inputs to the peripherals are of the likes:
- iodev_req(IODEV_UART0)
- iodev_rsp(IODEV_UART0)

Which are of the same type as the ones

The request / responses use wishbone / XBUS:
- xbus_req_t
- xbus_resp_t

### Request handling
- For every device in num_devs_c generat if the dev_en_list_c(i) is enabled
	- It sets the dev_req(i) to main_req
	- Does an address check
		- Sets the strobe if the address check's ok.


```v
bus_request: process(main_req)
begin
	dev_req(i) <= main_req;
	if (main_req.addr(addr_hi_c downto addr_lo_c) = dev_base_list_c(i)(addr_hi_c downto addr_lo_c)) then
		dev_req(i).stb <= main_req.stb; -- propagate transaction strobe if address match
	else
		dev_req(i).stb <= '0';
	end if;
end process bus_request;
```

### Response handling
Sets tmp_v-data from the dev_rsp(i)
- rsp_terminate_c: default bad response indicated in neorv32_package.vhd


```v
bus_response: process(dev_rsp)
	variable tmp_v : bus_rsp_t;
begin
	tmp_v := rsp_terminate_c; -- start with all-zero
	for i in 0 to (num_devs_c-1) loop -- OR all enabled response buses
		if dev_en_list_c(i) then
			tmp_v.data := tmp_v.data or dev_rsp(i).data;
			tmp_v.ack  := tmp_v.ack  or dev_rsp(i).ack;
			tmp_v.err  := tmp_v.err  or dev_rsp(i).err;
		end if;
		end loop;
	main_rsp <= tmp_v;
end process;
```

# XBUS / WISHBONE BUS

```v
  type xbus_req_t is record
    addr : std_ulogic_vector(31 downto 0); -- access address
    data : std_ulogic_vector(31 downto 0); -- write data
    tag  : std_ulogic_vector(2 downto 0); -- access tag
    we   : std_ulogic; -- read/write
    sel  : std_ulogic_vector(3 downto 0); -- byte enable
    stb  : std_ulogic; -- strobe
    cyc  : std_ulogic; -- valid cycle
  end record;
```

```v
  type xbus_rsp_t is record
    data : std_ulogic_vector(31 downto 0); -- read data, valid if ack=1
    ack  : std_ulogic; -- access acknowledge
    err  : std_ulogic; -- access error
  end record;
```

# neorv32_bus_reg
Enables a request and response register for the bus.
Probably for pipelining purposes.

## Signals
- clk_i, rstn_i
- host_req_i
- host_rsp_o
- device_req_o
- device_rsp_i

## Structure
request_reg_enabled-block
- process(rstn_i, clk_i)

The only 2 things that happen here are:
- device_req_o <= host_req_i;
- host_rsp_o <= device_rsp_i;


# neorv32_bus_switch

This entity serves the purpose of having
- An arbitration policy for what bus-requests happen first
- It manages 3 different buses

## Signals
### Port A request / Response bus (data memory cache )
- a_req_i, a_rsp_o: host port A response/request bus

### Port B request / response bus (instruction memory cache)
- b_req_i, b_rsp_o

### Device port Request / Response bus
- x_req_i, x_req_o

# neorv32_bus_gateway_inst

## signals
- clk_i
- rstn_i

## host port
- req_i
- rsp_o
## Section port
- a_req, a_rsp
- b_req, b_rsp
- c_req, c_resp
- x_req, x_resp

## Architecture
The host requests (req_i) goes through the address section decoder.
Depending on which memory is addressed, it selects the relevant port (port_sel(0), port_sel(1), port_sel(2), port_sel(3))

Selects it based on
- A_SIZE, A_BASE, ..
- When no port is selected (port_sel = 0) xbus is addressed.

### Bus request
- Redirects the request to the appropriate port, if the port is enabled

### Bus response
- Sets the port response depending on the port enabled

### Host response
- sets rsp_o from int_rsp

### Bus monitor
Is kind-of a "broker"

# Questions
### What if 2 requests / 2 responses are made at the same time? There's only a single bus.
- The request is only accepted if the strobe is set.
- The strobe is set only if the relevant bus address for the device is appropriate.

### How is data and instruction memory addressed?
There is a module called "neorv32_dmem".

It takes an
- input bus request: bus_req_i 
- an output bus response: bus_rsp_o


### Is there a single bus for both instruction and data memory?
There's a
- imem_req, imem_resp
- dmem_req, dmem_resp

And they seem to be driven by the same neorv32_bus_gateway

### Is the instruction memory and data memory fetched from the same location? Or is there physical separation between memory?

It seems like the instruction memory is separate from the data-memory.
They both have separate sizes (IMEM_SIZE) and (DMEM_SIZE).
The instruction memory also has a region that can be 