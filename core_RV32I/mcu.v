`timescale 1ns/10ps

module mcu(
    input clkin,
    input nrst_in
);

core #() core_t (.sysclk(clkin), .nrst_in(nrst_in));

endmodule
