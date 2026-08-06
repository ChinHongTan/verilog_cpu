`ifndef TOP_SVH
	`define TOP_SVH

	timeunit 1ns;
	timeprecision 1ps;
	`include "ALU_Pkg.sv"
	`include "FSM_State_Pkg.sv"

	// MARK: Registers
	`define REG_ADDR 3
	`define REG_WIDTH 16

	typedef logic [`REG_WIDTH - 1:0] RegData;
	typedef logic [`REG_ADDR - 1:0] RegAddr;
	typedef RegData Reg_array [0:(1 << `REG_ADDR) - 1]; 

	typedef enum logic {
		READ  = 1'b0,
		WRITE = 1'b1
	} RW;

	// MARK: RAM
	`define ADDR_WIDTH 8
	`define DATA_WIDTH 32
	`define MEM_INIT_FILE "ex1.mem"

	typedef logic [`DATA_WIDTH - 1:0] RAM_Data;	
	typedef logic [`ADDR_WIDTH - 1:0] RAM_Address;

	// MARK: Instructions
	typedef enum logic [4:0] {
		OP_ADD   = 5'b00001,
		OP_SUB   = 5'b00010,
		OP_MUL   = 5'b00011,
		OP_DIV   = 5'b00100,
        OP_JMP   = 5'b00101,
        OP_JNZ   = 5'b00110,
        OP_HALT  = 5'b00111,
        OP_STORE = 5'b01000,
        OP_LOAD  = 5'b01001,
        OP_LOADI = 5'b01010,
		OP_MOV   = 5'b01011,
		OP_JAL	 = 5'b01100,
		OP_JMPR  = 5'b01101
	} operation_t;

	`define MAX(a, b) (((a) > (b)) ? (a) : (b))
	`define MIN(a, b) (((a) < (b)) ? (a) : (b))

    /** return 255 if overflow */
    function automatic [7:0] overflow_16to8b(input [15:0] a);
        return (|a[15:8]) ? 8'hFF : a[7:0]; 
    endfunction
`endif
