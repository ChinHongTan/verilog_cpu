`include "top.svh";
`include "IR_Pkg.sv";
`include "ALU_Pkg.sv";

module top(
	input clk,
	input rst_n
);
	import ALU_Pkg::*;

	logic clk_1Hz;
    ALU_Mode mode;
	RegData reg1, reg2, result;

	to1Hz to1Hz_inst(
        .clk,
		.rst_n,
		.out(clk_1Hz)
    );

    logic write_enable;
    
    Registers TODO (
        .clk,
        .rst_n,
        .address1,
        .address2,
        .data_out1(reg1),
        .data_out2(reg2),

        .write(write_enable), //TODO
        .data_in(0)
    );

    ALU alu_inst (
        .clk,
        .rst_n,
        .data1(reg1),
        .data2(reg2),
        .mode,
        .result
    );

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic if needed
        end else begin
            // Additional logic if needed
        end
    end
endmodule
