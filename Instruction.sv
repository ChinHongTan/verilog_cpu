`include "top.svh";
`include "IR_Pkg.sv";

module Instruction
	import IR_Pkg::*;
(
	input clk,
    input rst_n,
	input IR_code ir_code,
	input RegData reg1, reg2,
	output logic [31:0] result,
);
endmodule
