`ifndef TOP_SVH
	`define TOP_SVH

	typedef logic [7:0] RegData;
	typedef logic [2:0] RegAddr;
	typedef RegData Reg_array [0:7]; 

	typedef enum logic {
		READ = 1'b0,
		WRITE = 1'b1
	} RW;
	
	`define ADDR_WIDTH 8
	`define DATA_WIDTH 32
	`define MEM_INIT_FILE "ex1.mem"

	typedef logic [`DATA_WIDTH - 1:0] RAM_Data;
`endif
