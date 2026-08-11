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
		OP_NOP	  = 5'd0,
		OP_ADD    = 5'd1,
        OP_SUB    = 5'd2,
        OP_MUL    = 5'd3,
        OP_DIV    = 5'd4,
		OP_ADDI   = 5'd5,
		OP_SUBI   = 5'd6,
        OP_MOV    = 5'd7,
        OP_LOAD   = 5'd8,       // Save to register with an immediate number, e.g. LOADI R0 2
        OP_LOADI  = 5'd9,
        OP_LOADR  = 5'd10,       // Save to RAM
        OP_STORE  = 5'd11,
		OP_STORER = 5'd12,
        OP_JMP    = 5'd13,      // Jump if the register is zero, e.g. JZ R3 ADD_SECTION
        OP_JNZ    = 5'd14,
        OP_JAL 	  = 5'd15,
        OP_JMPR   = 5'd16,
		OP_BEQ    = 5'd17,
		OP_BNE    = 5'd18,
		OP_BLT    = 5'd19,
		OP_BGE    = 5'd20,
        OP_HALT   = 5'd21
	} operation_t;

    typedef enum logic [2:0] {
        FETCH       = 3'd0,
        DECODE      = 3'd1,
        EXECUTE     = 3'd2,
        WRITE_RAM   = 3'd3,
        WRITE_REG   = 3'd4
    } stage_t;

	typedef enum logic [0:0] {
		false = 1'b0,
		true  = 1'b1
	} bool;

	`define MAX(a, b) (((a) > (b)) ? (a) : (b))
	`define MIN(a, b) (((a) < (b)) ? (a) : (b))

    /** return 255 if overflow */
    function automatic [7:0] overflow_16to8b(input [15:0] a);
        return (|a[15:8]) ? 8'hFF : a[7:0]; 
    endfunction

	`define isSigned 0

	typedef enum logic [2:0] {
        NONE		= 3'd0,
        CALC        = 3'd1,
        MOV         = 3'd2,
        STORE       = 3'd3,
		STORER      = 3'd4,
		JUMP		= 3'd5,
		HALT        = 3'd7
	} execute_mode_t;
`endif
