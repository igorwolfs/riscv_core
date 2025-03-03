`timescale 1ns/10ps

module dmemory #(parameter INT_DMEM_SIZE = 1024)
(
    input CLK,
    input NRST,
    // WRITE
    input AWVALID,
    input [31:0] AWADDR,
    input [31:0] WDATA,
    // READ
    input [31:0] ARADDR,
    output [31:0] RDATA
);

reg [31:0] ROM[INT_DMEM_SIZE-1:0];
always @(posedge CLK)
begin
    if (AWVALID)
    begin
        ROM[AWADDR] <= WDATA;
    end
end

assign RDATA = ROM[ARADDR];

endmodule
