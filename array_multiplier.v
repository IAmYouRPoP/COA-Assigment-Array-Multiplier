`timescale 1ns/1ps

// 16x16 Array Multiplier 

module array_multiplier (
    input  [15:0] in_A,
    input  [15:0] in_B,
    output [31:0] prod_out
);


    wire [15:0] pp [15:0];  // 16x16 partial product matrix
    genvar i, j;

    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_PP_ROW
            for (j = 0; j < 16; j = j + 1) begin : GEN_PP_COL
                assign pp[i][j] = in_A[j] & in_B[i];
            end
        end
    endgenerate

    wire [31:0] row_sum [15:0];
    wire [31:0] row_carry [15:0];

    assign row_sum[0]   = {16'b0, pp[0]};
    assign row_carry[0] = 32'b0;

    genvar r;
    generate
        for (r = 1; r < 16; r = r + 1) begin : ADDER_ROWS
            wire [31:0] shifted_pp = { {16 - r{1'b0}}, pp[r], {r{1'b0}} };
            adder32 ADD_STAGE (
                .in_a(row_sum[r-1]),
                .in_b(shifted_pp),
                .cin(1'b0),
                .sum(row_sum[r]),
                .cout(row_carry[r])
            );
        end
    endgenerate

    assign prod_out = row_sum[15];

endmodule

// 32-bit Ripple Carry Adder (Structural)

module adder32 (
    input  [31:0] in_a,
    input  [31:0] in_b,
    input         cin,
    output [31:0] sum,
    output        cout
);
    wire [31:0] carry;
    genvar k;

    full_adder FA0 (.a(in_a[0]), .b(in_b[0]), .cin(cin), .sum(sum[0]), .cout(carry[0]));
    generate
        for (k = 1; k < 32; k = k + 1) begin : FA_CHAIN
            full_adder FAi (.a(in_a[k]), .b(in_b[k]), .cin(carry[k-1]), .sum(sum[k]), .cout(carry[k]));
        end
    endgenerate

    assign cout = carry[31];
endmodule

module full_adder (
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule
