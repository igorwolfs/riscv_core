`timescale 1ns/10ps

module dmemory #(parameter mem_content_path = "tests/my.hex",
                parameter signature_path = "tests/my.sig")
(
    input clkin,
    input nrst_in,
    // WRITE
    input wr_en_in,
    input [31:0] wr_addr_in,
    input [31:0] wr_data_in,
    // READ
    input [31:0] rd_addr_in,
    output [31:0] rd_data_out
);

reg [31:0] ROM[255:0];
always @(posedge clkin)
begin
    if (wr_en_in)
    begin
        ROM[wr_addr_in] <= wr_data_in;
    end
end

assign rd_data_out = ROM[rd_addr_in];

endmodule
