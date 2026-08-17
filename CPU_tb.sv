`timescale 1ns / 1ps
`define SIM_SPEEDUP

module CPU_tb;
    logic clk;
    logic [15:0] sw;
    logic [15:0] led;
    logic [7:0] seg;
    logic [3:0] an;

    top top_inst(
        .clk(clk),
        .sw(sw),
        .led(led),
        .seg(seg),
        .an(an)
    );
    always #5 clk <= ~clk;

    initial begin
        $dumpfile("wave.vcd"); 
        $dumpvars(1, CPU_tb);   
        clk = 1'b1;
        sw = 16'b0;
        #5 sw = 16'b1;

        #8 sw[15] = 1'b1;
        #10 sw[15] = 1'b0;

        #200 $finish;
    end
endmodule
