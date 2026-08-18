`ifndef ALU_PKG_SV
	`define ALU_PKG_SV
	package ALU_Pkg;
		typedef enum logic [3:0] {
			ADD = 4'b0000,
			SUB = 4'b0001,
			MUL = 4'b0010,
			DIV = 4'b0011,
            AND = 4'b0100,
            OR  = 4'b0101,
            XOR = 4'b0110,
            NOT = 4'b0111,
            SHL = 4'b1000,
            SHR = 4'b1001
		} ALU_Mode;

		typedef enum logic [0:0] {
			ALU_IDLE = 1'b0,
			ALU_DONE = 1'b1
		} ALU_state_t;
	endpackage
`endif
