`timescale 1ns/10ps

// 1 MB: 0b1111_11111111_11111111 = 20 bits = 0xFFFFF

module top_tb ();

//! >>> TEST
reg NRST = 1, CLK = 0;

initial
begin
    NRST = 0;
    #2;
    NRST = 1;
    #2;
end

always #1 CLK = ~CLK; //255  65536*8
wire UART_TX_DSER, UART_RX_DSER;
assign UART_RX_DSER = UART_TX_DSER;
    riscv_mcu #(.INT_MEM_SIZE(256),
    .CLOCK_FREQUENCY(500_000_000),
    .AXI_AWIDTH(32),
    .AXI_DWIDTH(32)) riscv_mcu_inst (
    .CLK(CLK),
    .NRST(NRST),
    .UART_TX_DSER(UART_TX_DSER),
    .UART_RX_DSER(UART_RX_DSER)
   );

//! <<< TEST
endmodule
