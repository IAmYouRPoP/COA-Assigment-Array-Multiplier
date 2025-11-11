`timescale 1ns/1ps

module tb_wallace_multiplier;

    // Testbench signals
    reg clk_sig;
    reg rst_sig;
    reg [15:0] in_A, in_B;
    wire [31:0] prod_out;

    // DUT instance
    wallace_7to3_unsigned dut_inst (
        .clk(clk_sig),
        .rst(rst_sig),
        .A(in_A),
        .B(in_B),
        .P(prod_out)
    );

    // Clock generation: 10 ns period
    always #5 clk_sig = ~clk_sig;

    integer tcase;
    reg [31:0] golden_product;

    initial begin
        clk_sig = 0;
        rst_sig = 1;
        in_A = 0;
        in_B = 0;

        // Reset
        #20;
        rst_sig = 0;

        // 10 random tests
        for (tcase = 0; tcase < 10; tcase = tcase + 1) begin
            @(posedge clk_sig);
            in_A = $random;
            in_B = $random;
            golden_product = in_A * in_B;

            // Wait pipeline delay (≈5-6 cycles)
            repeat (6) @(posedge clk_sig);

            if (prod_out === golden_product)
                $display("✅ Pass[%0d]: A=%0d B=%0d → P=%0d", tcase, in_A, in_B, prod_out);
            else
                $display("❌ Fail[%0d]: A=%0d B=%0d → Expected=%0d Got=%0d",
                         tcase, in_A, in_B, golden_product, prod_out);
        end

        $display("\nTestbench finished: 10 random cases verified.");
        $stop;
    end

endmodule
