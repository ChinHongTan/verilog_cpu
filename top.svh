`ifndef TOP_SVH
	`define TOP_SVH

	typedef logic [7:0] RegData;

	typedef enum logic {
		READ = 1'b0,
		WRITE = 1'b1
	} RW;

`endif
