`ifndef IR_PKG_SV
	`define IR_PKG_SV
	package IR_Pkg;
		typedef enum logic [3:0] {
			ADD  = 4'd1,  
			SUB  = 4'd2,  
			MUL  = 4'd3,  
			DIV  = 4'd4,  
			MOV  = 4'd5,  
			JUP  = 4'd6,  
			JZ   = 4'd7,  
			HALT = 4'd8,
            WRITE = 4'd9,
            READ = 4'd10
		} IR_code;
	endpackage
`endif
