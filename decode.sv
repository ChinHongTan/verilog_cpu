`include "top.svh"

module decode(
	input clk,
	input rst_n,
	input RAM_Data command,
	input RegData regData1, regData2,
	input equ, less, greater_or_equal,

	output bool load_de,
	output RW write_enable_de,
	output RW RAM_write_enable_de,
	output RegData Data1_de, Data2_de,
	output RegAddr address1, address2,
	output RegAddr address_write_de,
    output ALU_Pkg::ALU_Mode ALU_mode,
	output execute_mode_t execute_mode,
	output logic jump_condition,
    output bool jal
);
	operation_t opcode;
    RegData imm;

	// MARK: Decode addr
    always_ff @(posedge clk or negedge rst_n) begin : decode_stage
        if (!rst_n) begin
            opcode           <= OP_NOP;
            address_write_de <= 3'b0;         // first reg
            address1         <= 3'b0;         // second reg
            address2         <= 3'b0;         // third reg
            imm              <= 16'b0;        // immediate value
        end else begin
            opcode           <= operation_t'(command[31:27]);
            address_write_de <= command[26:24];         // first reg
            address1         <= command[23:21];         // second reg
            address2         <= command[20:18];         // third reg
            imm              <= command[17:2];          // immediate value
        end
    end

    always_comb begin : ALU_Control
        case (opcode)
            OP_ADD, OP_ADDI: begin
                ALU_mode = ALU_Pkg::ADD;
            end

            OP_SUB, OP_SUBI: begin
                ALU_mode = ALU_Pkg::SUB;
            end

            OP_MUL: begin
                ALU_mode = ALU_Pkg::MUL;
            end

            OP_DIV: begin
                ALU_mode = ALU_Pkg::DIV;
            end
            
            default: begin : comparing_signal
                ALU_mode = ALU_Pkg::SUB;
            end
        endcase
    end

	// MARK: Decode stage
    always_comb begin : decode_control
        Data1_de = 0;
        Data2_de = 0;
        jump_condition = false;
        write_enable_de = READ;
        RAM_write_enable_de = READ;
        execute_mode = NONE;
        load_de = false;
        jal = false;
        case (opcode) // execute stage
            OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin
                Data1_de = regData1;
                Data2_de = regData2;
                write_enable_de = WRITE;
                execute_mode = CALC;
            end
            OP_ADDI, OP_SUBI: begin
                Data1_de = regData1;
                Data2_de = imm;
                write_enable_de = WRITE;
                execute_mode = CALC;
            end

            OP_STORE: begin
                Data1_de = regData1;
                Data2_de = imm;
                RAM_write_enable_de = WRITE;
                execute_mode = STORE;
            end

            OP_STORER: begin 
                RAM_write_enable_de = WRITE;
                execute_mode = STORER;
            end

            OP_MOV: begin
                write_enable_de = WRITE;
                execute_mode = MOV;
            end

            // Memory
            OP_LOAD: begin
                write_enable_de = WRITE;
                load_de = true;
            end

            OP_LOADI: begin
                write_enable_de = WRITE;
                Data1_de = imm;
            end

            OP_LOADR: begin // LOADR R0 R1 ; R0 = BRAM[R1]
                write_enable_de = WRITE;
                load_de = true;
            end

            // Jump and Branch
            OP_JMP: begin
                Data1_de = imm;
                jump_condition = true;
                execute_mode = JUMP;
            end
            OP_JNZ: begin
                Data1_de = imm;
                jump_condition = (regData1 != 0);
                execute_mode = JUMP;
            end
            OP_JAL: begin
                Data1_de = imm;
                jump_condition = true;
                write_enable_de = WRITE;
                execute_mode = JUMP;

                jal = true;
            end
            OP_JMPR: begin
                Data1_de = regData1;
                jump_condition = true;
                execute_mode = JUMP;
            end

            OP_BEQ: begin
                Data1_de = imm;
                jump_condition = equ;
                execute_mode = JUMP;
            end
            OP_BNE: begin
                Data1_de = imm;
                jump_condition = ~equ;
                execute_mode = JUMP;
            end 
            OP_BLT: begin
                Data1_de = imm;
                jump_condition = less;
                execute_mode = JUMP;
            end 
            OP_BGE: begin
                Data1_de = imm;
                jump_condition = greater_or_equal;
                execute_mode = JUMP;
            end
            OP_HALT: begin
                execute_mode = HALT;
            end
            OP_NOP: begin
                execute_mode = NONE;
            end
            default: begin
            end
        endcase
    end
endmodule
