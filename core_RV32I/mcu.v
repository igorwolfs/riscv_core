`timescale 1ns/10ps

module mcu(
    input CLK,
    input NRST
);

core #() core_t (.sysclk(CLK), .NRST(NRST));

endmodule
