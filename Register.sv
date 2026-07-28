`include "top.svh";
`include "IR_Pkg.sv";
`include "ALU_Pkg.sv";


module Register(
    input clk,
    input rst_n,
    input select, 
	input RW read_write, // 0:read 1:write
    input RegData data_in,
    output RegData data_out
);

	RegData saved;
    always_ff @(posedge clk, negedge rst_n) begin
			 if (!rst_n) 	 			saved <= 8'b0;
		else if (select && read_write)	saved <= data_in;
    end
    
	always_comb begin
		if (select && !read_write) 	data_out = saved;
		else 						data_out = 8'b0;
	end
endmodule
