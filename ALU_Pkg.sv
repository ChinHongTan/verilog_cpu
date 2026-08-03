`ifndef ALU_PKG_SV
	`define ALU_PKG_SV
	package ALU_Pkg;
		typedef enum logic [2:0] {
			ADD = 3'b000,
			SUB = 3'b001,
			MUL = 3'b010,
			DIV = 3'b011
		} ALU_Mode;

		typedef enum logic [0:0] {
			ALU_IDLE = 1'b0,
			ALU_DONE = 1'b1
		} ALU_state_t;
	endpackage
`endif
