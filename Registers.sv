`include "top.svh";

module Registers( // double IO
    input clk,
    input rst_n,
    input RegAddr address1, address2,
	output RegData data_out1, data_out2,

	input RW write, // 0:read 1:write
	input RegAddr address_write,
    input RegData data_in
);
	Reg_array saved_reg;
	always_comb begin : data_read
		data_out1 = saved_reg[address1];
		data_out2 = saved_reg[address2];
	end

    always_ff @(posedge clk, negedge rst_n) begin : data_write
			 if (!rst_n) saved_reg <= '{default:RegData'(0)};
		else if (write)	 saved_reg[address_write] <= data_in;
    end
endmodule
