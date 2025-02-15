## This file is a general .xdc for the Arty-S7 Rev. C
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
#set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33 } [get_ports { CLK12MHZ }]; #IO_L13P_T2_MRCC_15 Sch=uclk
#create_clock -add -name sys_clk_pin -period 83.333 -waveform {0 41.667} [get_ports { CLK12MHZ }];
set_property -dict {PACKAGE_PIN R2 IOSTANDARD SSTL135} [get_ports sysclk];
# create 10 MHz waveform
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports sysclk];

# BUTTON 0: HIGH (away from edge), LOW (towards edge)
set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { nrst_in }]; #IO_L20N_T3_A19_15 Sch=sw[0]
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { nrst_led_out }]; #IO_L16N_T2_A27_15 Sch=led[2]

## BUTTONS
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {button_in[0]}];
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {button_in[1]}];
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports {button_in[2]}];
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports {button_in[3]}];


## PMOD Header JA ARR[2][6]
# ARR[1][0]
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { uart_tx_serial_out }]; #IO_L4P_T0_D04_14 Sch=ja_p[1]
# ARR[1][1]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { uart_tx_busy_out }]; #IO_L4N_T0_D05_14 Sch=ja_n[1]
# set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { uart_tx_done_out }]; #IO_L5N_T0_D07_14 Sch=ja_n[2]


##Configuration options, can be used for all designs
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

set_property INTERNAL_VREF 0.675 [get_iobanks 34]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]