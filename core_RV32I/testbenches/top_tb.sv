module top_tb #(parameter mem_content_path="tests/my.hex",
                parameter signature_path = "tests/my.sig")();

    reg sysclk = 0, nrst_in = 1;

    core #() core_t (.sysclk(sysclk), .nrst_in(nrst_in));

    always #5 sysclk = ~sysclk;
    initial
    begin
        nrst_in <= 0;
        #10;
        nrst_in <= 1;
    end

endmodule
