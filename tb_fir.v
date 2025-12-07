// tb_fir.v
`timescale 1ns/1ps
module tb_fir;
    parameter TAPS = 8;
    parameter IN_WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg signed [IN_WIDTH-1:0] in_sample;
    reg in_valid;
    wire signed [IN_WIDTH-1:0] out_sample;
    wire out_valid;

    // instantiate DUT (instance name = dut)
    fir #(
        .TAPS(TAPS),
        .IN_WIDTH(IN_WIDTH),
        .COEFF_WIDTH(16),
        .FRAC(8)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_sample(in_sample),
        .in_valid(in_valid),
        .out_sample(out_sample),
        .out_valid(out_valid)
    );

    // clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // stimulus and VCD dump
    integer step;
    initial begin
        // dump waves for EDA Playground (capture all modules and signals)
        $dumpfile("fir_tb.vcd");
        $dumpvars(0); // ensures .dut and its internals are recorded

        $display("VCD dump started");

        rst_n = 0;
        in_sample = 0;
        in_valid = 0;
        # (2*CLK_PERIOD);
        rst_n = 1;
        # (CLK_PERIOD);

        // Impulse response
        $display("----- Impulse -----");
        in_sample = 16'sd256; // '1.0' with FRAC=8
        in_valid = 1;
        #(CLK_PERIOD);
        in_valid = 0;
        in_sample = 0;
        repeat (16) #(CLK_PERIOD);

        // Step response
        $display("----- Step -----");
        repeat (16) begin
            in_sample = 16'sd256;
            in_valid = 1;
            #(CLK_PERIOD);
        end
        in_valid = 0;
        #(4*CLK_PERIOD);

        // done
        $display("Simulation finished.");
        # (2*CLK_PERIOD);
        $finish;
    end

    // monitor outputs
    initial begin
        $display("time\tin_valid\tin_sample\tout_valid\tout_sample");
        forever @(posedge clk) begin
            $display("%0t\t%b\t\t%0d\t\t%b\t\t%0d", $time, in_valid, in_sample, out_valid, out_sample);
        end
    end

endmodule
