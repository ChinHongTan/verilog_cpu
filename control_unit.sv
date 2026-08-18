`include "top.svh"

module control_unit(
	input clk,
	input rst_n,
	input RAM_Data command,
	input RegData regData1, regData2,
    input clear_op,
	input equ, less, greater_or_equal,
    input pause,

	output bool load_de,
	output RW write_enable_de,
	output RW RAM_write_enable_de,
	output RegData Data1_de, Data2_de,
	output RegData jump_target,      // immediate target
	output RegAddr address1, address2,
	output RegAddr address_write_de,
    output bool read1, read2,
    output ALU_Pkg::ALU_Mode ALU_mode,
	output execute_mode_t execute_mode,
	output logic jump_condition,
    output bool jal,
    output logic updated
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
        end else if (clear_op | !updated) begin
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

    RAM_Address RAM_addr_prev;
    bool write_prev;

    wire write_signal = (opcode == OP_STORE || opcode == OP_STORER);
    wire read_signal = (opcode == OP_LOAD || opcode == OP_LOADR);
    wire same = (RAM_addr_prev == Data2_de[7:0]);
    always_ff @(posedge clk or negedge rst_n) begin : RAM_write_stage
        write_prev <= false;
        if (!rst_n) begin
            RAM_addr_prev <= 0;
            write_prev    <= false;
        end else if (!pause && !clear_op) begin
            if (write_signal) begin
                RAM_addr_prev <= regData2[7:0];
                write_prev <= true;
            end else if (read_signal) begin
                RAM_addr_prev <= regData2[7:0];
            end
        end
    end

	// MARK: Decode stage
    always_comb begin : decode_control
        Data1_de = 0;
        Data2_de = 0;
        jump_target = 0;
        write_enable_de = READ;
        RAM_write_enable_de = READ;
        execute_mode = NONE;
        load_de = false;
        jal = false;
        read1 = false;
        read2 = false;
        if (!clear_op || !pause) case (opcode) // execute stage
            OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin
                Data1_de = regData1;
                Data2_de = regData2;
                read1 = true;
                read2 = true;
                write_enable_de = WRITE;
                execute_mode = CALC;
            end
            OP_ADDI, OP_SUBI: begin
                Data1_de = regData1;
                Data2_de = imm;
                read1 = true;
                write_enable_de = WRITE;
                execute_mode = CALC;
            end

            OP_MOV: begin
                Data1_de = regData1;
                read1 = true;
                write_enable_de = WRITE;
                execute_mode = MOV;
            end

            // Memory
            OP_STORE: begin
                Data1_de = regData1;
                Data2_de = imm;		 // RAM addr
                read1 = true;
                RAM_write_enable_de = WRITE;
                execute_mode = STORE;
            end

            OP_STORER: begin 
                Data1_de = regData1;
                Data2_de = regData2; // RAM addr
                read1 = true;
                RAM_write_enable_de = WRITE;
                execute_mode = STORER;
            end

            OP_LOAD: begin
                Data1_de = regData1;
                Data2_de = imm;		 // RAM addr
                write_enable_de = WRITE;
                load_de = true;
                execute_mode = LOAD;
            end

            OP_LOADI: begin
                Data1_de = imm;
                write_enable_de = WRITE;
                execute_mode = MOV;
            end

            OP_LOADR: begin // LOADR R0 R1 ; R0 = BRAM[R1]
                Data1_de = regData1;
                Data2_de = regData2; // RAM addr
                write_enable_de = WRITE;
                load_de = true;
                execute_mode = LOAD;
            end

            // Jump and Branch
            OP_JMP: begin
				jump_target = imm;
                execute_mode = JUMP;
            end
            OP_JNZ: begin
                Data1_de = regData1;
				jump_target = imm;
                read1 = true;
                execute_mode = JUMP;
            end
            OP_JAL: begin
				jump_target = imm;
                write_enable_de = WRITE;
                execute_mode = JUMP;

                jal = true;
            end
            OP_JMPR: begin
                jump_target = regData1;
                read1 = true;
                execute_mode = JUMP;
            end

            OP_BEQ, OP_BNE, OP_BLT, OP_BGE: begin
                Data1_de = regData1;
                Data2_de = regData2;
				jump_target = imm;
                read1 = true;
                read2 = true;
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

    always_comb begin : branch_condition
        jump_condition = false;
        updated = true;
        if (!clear_op) case (opcode)
            OP_JMP, OP_JAL, OP_JMPR: begin jump_condition = true;   updated = ~jump_condition; end     // unconditional
            OP_JNZ:                  begin jump_condition = ~equ;   updated = ~jump_condition; end     // regData1 != 0
            OP_BEQ:                  begin jump_condition = equ;    updated = ~jump_condition; end
            OP_BNE:                  begin jump_condition = ~equ;   updated = ~jump_condition; end
            OP_BLT:                  begin jump_condition = less;   updated = ~jump_condition; end
            OP_BGE:                  begin jump_condition = greater_or_equal; updated = ~jump_condition; end
            OP_LOAD, OP_LOADR:       begin if (write_prev || !same) updated = false; end
            default:                 begin jump_condition = false;  updated = ~jump_condition; end
        endcase
    end
endmodule
