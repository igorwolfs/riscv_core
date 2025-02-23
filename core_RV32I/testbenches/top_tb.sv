module top_tb #(parameter mem_content_path="tests/my.hex",
                parameter signature_path = "tests/my.sig")
    ();

    reg sysclk = 0, nrst_in = 1;
    // External memory interface (when INTERNAL_MEMORY = 0)
    // Data Memory Interface
    wire [31:0] dmem_rd_addr, dmem_rd_data, dmem_wr_addr, dmem_wr_data;
    wire dmem_wr_en;

    // Instruction Memory Interface
    wire [31:0] imem_addr, imem_data;

    core #(.INTERNAL_MEMORY(0)) core_t (.sysclk(sysclk), .nrst_in(nrst_in),
    // Data
    .dmem_rd_addr(dmem_rd_addr), .dmem_rd_data(dmem_rd_data), .dmem_wr_addr(dmem_wr_addr),
    .dmem_wr_data(dmem_wr_data), .dmem_wr_en(dmem_wr_en),
    // Instructions
    .imem_addr(imem_addr), .imem_data(imem_data));

    always #5 sysclk = ~sysclk;
    initial
    begin
        nrst_in = 0;
        #10;
        nrst_in = 1;
    end

endmodule

/**
IDEA 1:
- Create a function that on "read" reads memory from the hex file and loads it.
- Then set the reset vector as well as the instruction pointer appropriately to start.
- Then run the code
- While running check for memory values indicating signature region
- Write the signature values to a separate file
*/
