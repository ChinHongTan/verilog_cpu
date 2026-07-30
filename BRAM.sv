`include "top.svh";

module BRAM (
    input clk,
	input RW write, // 0:read 1:write
	input [7:0] address,
	input RAM_Data in,
	output RAM_Data out
);
	RAM_Data bram [0:(1 << `ADDR_WIDTH)-1]; // there're 256 "RAM_Data"

	initial begin : init_bram
		if (`MEM_INIT_FILE != "") begin
			$readmemh(`MEM_INIT_FILE, bram);
		end
	end

	always_ff @(posedge clk) begin : bram_access // NEVER RESET RAM
		if (write) begin
			bram[address] <= in;    // write operation
		end
		out <= bram[address];       // synchronous read
	end
endmodule
