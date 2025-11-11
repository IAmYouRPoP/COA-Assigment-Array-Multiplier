`timescale 1ns/1ps

// 16x16 Wallace-Tree Multiplier using 7:3 Compressors

// Main Top Module
module wallace_7to3_unsigned (
    input clk,
    input rst,
    input  [15:0] A,
    input  [15:0] B,
    output reg [31:0] P
);
    integer j;

    // Partial products
    wire [31:0] pp [0:15];
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1)
            assign pp[k] = ({16'b0, (A & {16{B[k]}})} << k);
    endgenerate

    // Layer 1: 16 -> 8
    wire [31:0] s1_0, c1_0a, c1_0b;
    wire [31:0] s1_1, c1_1a, c1_1b;

    compressor73_vec32 STG1_A (pp[0],pp[1],pp[2],pp[3],pp[4],pp[5],pp[6], s1_0,c1_0a,c1_0b);
    compressor73_vec32 STG1_B (pp[7],pp[8],pp[9],pp[10],pp[11],pp[12],pp[13], s1_1,c1_1a,c1_1b);

    wire [31:0] lay1 [0:7];
    assign lay1[0] = s1_0;
    assign lay1[1] = c1_0a << 1;
    assign lay1[2] = c1_0b << 2;
    assign lay1[3] = s1_1;
    assign lay1[4] = c1_1a << 1;
    assign lay1[5] = c1_1b << 2;
    assign lay1[6] = pp[14];
    assign lay1[7] = pp[15];

    reg [31:0] r1 [0:7];
    always @(posedge clk) begin
        if (rst)
            for (j=0;j<8;j=j+1) r1[j] <= 32'b0;
        else
            for (j=0;j<8;j=j+1) r1[j] <= lay1[j];
    end

    // Layer 2: 8 -> 4 
    wire [31:0] s2_0, c2_0a, c2_0b;
    compressor73_vec32 STG2 (r1[0],r1[1],r1[2],r1[3],r1[4],r1[5],r1[6], s2_0,c2_0a,c2_0b);

    wire [31:0] lay2 [0:3];
    assign lay2[0] = s2_0;
    assign lay2[1] = c2_0a << 1;
    assign lay2[2] = c2_0b << 2;
    assign lay2[3] = r1[7];

    reg [31:0] r2 [0:3];
    always @(posedge clk) begin
        if (rst)
            for (j=0;j<4;j=j+1) r2[j] <= 32'b0;
        else
            for (j=0;j<4;j=j+1) r2[j] <= lay2[j];
    end

    // Layer 3: 4 -> 3
    wire [31:0] s3_0, c3_0a, c3_0b;
    compressor73_vec32 STG3 (r2[0],r2[1],r2[2],r2[3],32'b0,32'b0,32'b0, s3_0,c3_0a,c3_0b);

    reg [31:0] r3_0, r3_1, r3_2;
    always @(posedge clk) begin
        if (rst) begin
            r3_0 <= 0;
            r3_1 <= 0;
            r3_2 <= 0;
        end else begin
            r3_0 <= s3_0;
            r3_1 <= c3_0a << 1;
            r3_2 <= c3_0b << 2;
        end
    end

    // Layer 4: 3 -> 2 (Carry-Save Adder) 
    wire [31:0] s4_unreg, c4_unreg;
    csa_3to2_vec32 STG4 (
        .in_a(r3_0),
        .in_b(r3_1),
        .in_c(r3_2),
        .sum_vec(s4_unreg),
        .carry_vec(c4_unreg)
    );

    reg [31:0] r4_sum, r4_carry;
    always @(posedge clk) begin
        if (rst) begin
            r4_sum <= 0;
            r4_carry <= 0;
        end else begin
            r4_sum   <= s4_unreg;
            r4_carry <= c4_unreg << 1;
        end
    end

    // Final Adder 
    wire [31:0] final_sum;
    wire final_cout;
    final_adder_32 FINAL_ADD (
        .in_a(r4_sum),
        .in_b(r4_carry),
        .cin(1'b0),
        .sum(final_sum),
        .cout(final_cout)
    );

    always @(posedge clk) begin
        if (rst)
            P <= 32'b0;
        else
            P <= final_sum;
    end

endmodule

// Supporting Modules (Helper Blocks)

// 3:2 Carry-Save Adder 
module csa_3to2_vec32 (
    input  [31:0] in_a,
    input  [31:0] in_b,
    input  [31:0] in_c,
    output [31:0] sum_vec,
    output [31:0] carry_vec
);
    assign sum_vec   = in_a ^ in_b ^ in_c;
    assign carry_vec = (in_a & in_b) | (in_b & in_c) | (in_a & in_c);
endmodule


// 7:3 Compressor
module compressor73_vec32 (
    input  [31:0] in_a, in_b, in_c, in_d, in_e, in_f, in_g,
    output reg [31:0] sum_out,
    output reg [31:0] carry_1,
    output reg [31:0] carry_2
);
    integer idx;
    reg [2:0] count_bits;

    function [0:0] bit_to_one;
        input val;
        begin
            bit_to_one = (val === 1'b1) ? 1'b1 : 1'b0;
        end
    endfunction
    
    always @* begin
        for (idx = 0; idx < 32; idx = idx + 1) begin
            count_bits = bit_to_one(in_a[idx]) + bit_to_one(in_b[idx]) + bit_to_one(in_c[idx]) +
                         bit_to_one(in_d[idx]) + bit_to_one(in_e[idx]) + bit_to_one(in_f[idx]) + bit_to_one(in_g[idx]);
            sum_out[idx]  = count_bits[0];    
            carry_1[idx]  = count_bits[1];    
            carry_2[idx]  = count_bits[2];    
        end
    end
endmodule


// Final 32-bit Adder
module final_adder_32 (
    input  [31:0] in_a,
    input  [31:0] in_b,
    input         cin,
    output [31:0] sum,
    output        cout
);
    assign {cout, sum} = in_a + in_b + cin;
endmodule
