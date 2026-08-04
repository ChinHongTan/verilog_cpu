`ifndef FSM_STATE_PKG_SV
	`define FSM_STATE_PKG_SV
	package FSM_State_Pkg;
		typedef enum logic [1:0] {
			IDLE = 2'b00,
			FETCH = 2'b01,
			EXECUTE = 2'b10,
			HALT = 2'b11
		} state_t;
	endpackage
`endif
