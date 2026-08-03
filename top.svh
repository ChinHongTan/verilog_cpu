`ifndef TOP_SVH
	`define TOP_SVH

	typedef logic [7:0] RegData;
	typedef logic [2:0] RegAddr;
	typedef logic [3:0] RegAddrNum;
	typedef RegData Reg_array [0:7]; 

	typedef enum logic {
		READ = 1'b0,
		WRITE = 1'b1
	} RW;
	
	`define ADDR_WIDTH 8
	`define DATA_WIDTH 32
	`define MEM_INIT_FILE "ex1.mem"

	typedef logic [`DATA_WIDTH - 1:0] RAM_Data;	

	typedef enum logic [3:0] {
		OP_ADD = 4'b0001,
		OP_SUB = 4'b0010,
		OP_MUL = 4'b0011,
		OP_DIV = 4'b0100,
		OP_STORE = 4'b1001,
		OP_LOAD = 4'b1010,
		OP_LOADI = 4'b1011
	} operation_t;
`endif
