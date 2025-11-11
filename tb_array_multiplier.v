`timescale 1ns/1ps

module tb_array_multiplier;

    reg [15:0] in_A;
    reg [15:0] in_B;
    wire [31:0] prod_out;

    // Instantiate DUT
    array_multiplier dut_inst (
        .in_A(in_A),
        .in_B(in_B),
        .prod_out(prod_out)
    );

    integer tcase;
    reg [31:0] expected;

    initial begin
        $display("\n=== Testing 16x16 Structural Array Multiplier ===");

        for (tcase = 0; tcase < 10; tcase = tcase + 1) begin
            in_A = $random;
            in_B = $random;
            expected = in_A * in_B;
            #10; // combinational delay

            if (prod_out === expected)
                $display("✅ Pass[%0d]: A=%0d, B=%0d → P=%0d", tcase, in_A, in_B, prod_out);
            else
                $display("❌ Fail[%0d]: A=%0d, B=%0d → Expected=%0d, Got=%0d",
                         tcase, in_A, in_B, expected, prod_out);
        end

        $display("\nAll 10 random test cases completed.\n");
        $stop;
    end

endmodule
