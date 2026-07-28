`include "top.svh";

module BRAM_tb;
	logic clk;
	logic write;
	logic [7:0] address;

	RAM_Data in, out;

	BRAM BRAM_inst (
		.clk,
		.write, // 0:read 1:write
		.address,
		.in,
		.out
	);

	always #5 clk <= ~clk;

	initial begin
		write = 0;
		address = 0; #10;
		$display("Address=0 Data=%h", out); // Reads initial value 0x00

		address = 1; #10;
		$display("Address=1 Data=%h", out); // Reads initial value 0x01

		// Write to memory
			write = 1; address = 2; in = 32'h0055; 
		#10 write = 0; address = 2; 
		#10 $display("Address=2 Data(after write)=%h", out); // Reads 0x55


		$writememh("output.mem", BRAM_inst.bram);
		$display("✅ BRAM contents dumped to output.mem");
	end
endmodule
