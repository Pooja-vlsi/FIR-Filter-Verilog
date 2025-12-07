// fir.v
`timescale 1ns/1ps
module fir #(
    parameter TAPS = 8,
    parameter IN_WIDTH = 16,
    parameter COEFF_WIDTH = 16,
    parameter FRAC = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire signed [IN_WIDTH-1:0] in_sample,
    input  wire in_valid,
    output reg  signed [IN_WIDTH-1:0] out_sample,
    output reg  out_valid
);

    // --- coefficient function (returns integer scaled by 2^FRAC) ---
    // Keep coefficients here as integer literals (safe for all simulators).
    function signed [COEFF_WIDTH-1:0] coeff;
        input integer idx;
        begin
            case (idx)
                0: coeff = 16'sd2;
                1: coeff = 16'sd8;
                2: coeff = 16'sd18;
                3: coeff = 16'sd40;
                4: coeff = 16'sd40;
                5: coeff = 16'sd18;
                6: coeff = 16'sd8;
                7: coeff = 16'sd2;
                default: coeff = 16'sd0;
            endcase
        end
    endfunction

    // sample shift register
    reg signed [IN_WIDTH-1:0] samples [0:TAPS-1];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<TAPS; i=i+1) samples[i] <= 0;
        end else begin
            if (in_valid) begin
                for (i=TAPS-1; i>0; i=i-1) samples[i] <= samples[i-1];
                samples[0] <= in_sample;
            end
        end
    end

    // arithmetic widths
    localparam PRODUCT_WIDTH = IN_WIDTH + COEFF_WIDTH;
    function integer clog2;
        input integer value;
        integer j;
        begin
            clog2 = 0;
            for (j = value-1; j > 0; j = j >> 1)
                clog2 = clog2 + 1;
        end
    endfunction
    localparam ACC_WIDTH = PRODUCT_WIDTH + clog2(TAPS);

    // combinational multiply-accumulate
    reg signed [ACC_WIDTH-1:0] acc;
    reg signed [PRODUCT_WIDTH-1:0] products [0:TAPS-1];
    always @(*) begin
        acc = 0;
        for (i=0; i<TAPS; i=i+1) begin
            products[i] = $signed(samples[i]) * $signed(coeff(i));
            acc = acc + $signed(products[i]);
        end
    end

    // scale and register output
    wire signed [ACC_WIDTH-1:0] acc_shifted = acc >>> FRAC;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_sample <= 0;
            out_valid <= 1'b0;
        end else begin
            if (in_valid) begin
                out_sample <= acc_shifted[IN_WIDTH-1:0]; // truncation
                out_valid <= 1'b1;
            end else begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule
