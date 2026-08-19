`include "top.svh"

module BRAM #(
    parameter int ADDR_W = `DMEM_ADDR_WIDTH,
    parameter string INIT_FILE = ""   // only instruction memory is preloaded
) (
    input clk,
    input pause,
	input RW write, // 0:read 1:write
	input logic [ADDR_W - 1:0] address,
	input RAM_Data in,
	output RAM_Data out
);
	RAM_Data bram [0:(1 << ADDR_W)-1];

	initial begin : init_bram
		if (INIT_FILE != "") begin
			$readmemb(INIT_FILE, bram);
		end else begin
			bram = '{default: '0};
		end
	end

	always @(posedge clk) begin : bram_access // NEVER RESET RAM
		if (write) begin
			bram[address] <= in;    // write operation
		end
		if (!pause) begin
            out <= bram[address];       // synchronous read
        end
	end
endmodule
