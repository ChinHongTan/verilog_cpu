`include "top.svh";
`include "IR_Pkg.sv";
`include "ALU_Pkg.sv";

module top
(
	input clk,
	input rst_n
);

    always_ff @(posedge clk, negedge rst_n) begin

    end

	import ALU_Pkg::*;

	logic clk_1Hz;
    ALU_Mode mode;
	RegData reg1, reg2, result;

	to1Hz to1Hz_inst(
        .clk,
		.rst_n,
		.out(clk_1Hz)
    );

    ALU alu_inst(
        .clk,
		.rst_n,
		.reg1, 
		.reg2,
		.mode,
		.result
    );

endmodule
