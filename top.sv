`include "top.svh"

module top(
	input clk,
    input [15:0] sw,
    output logic [15:0] led,
    output [7:0] seg,
    output [3:0] an
);
    import FSM_State_Pkg::*;

    wire rst_n = sw[0];
    wire pause = sw[15];

	logic clk_1Hz;
    ALU_Pkg::ALU_Mode ALU_mode;

    // Registers
	RegData regData1, regData2;
    RegData ALU_Data1, ALU_Data2, result;
    RegData data_in;
    RegAddr address_write, address1, address2; // NEVER be number
    RW write_enable;

    // IR
    logic [15:0] pc; 
    RAM_Data command;

    // RAM
    RAM_Address RAM_addr; 
    RAM_Data RAM_in, RAM_out;
    RW RAM_write_enable;

    to1Hz to1Hz_inst(
        .clk,
		.rst_n,
		.out(clk_1Hz)
    );
    //assign clk_1Hz = clk; // for testBench debug

    Registers TODO (
        .clk(clk_1Hz),
        .rst_n,
        .address1(address1[2:0]),
        .address2(address2[2:0]),
        .data_out1(regData1),
        .data_out2(regData2),

        .write(write_enable),
        .address_write(address_write[2:0]),
        .data_in
    );

    

    BRAM Instruction(
        .clk(clk_1Hz),
        .write(1'b0), // 0:read 1:write
        .address(pc),
        .in(32'b0),
        .out(command)
    );

    BRAM RAM(
        .clk(clk_1Hz),
        .write(RAM_write_enable), 
        .address(RAM_addr),
        .in(RAM_in),
        .out(RAM_out)
    );

    state_t state;
    control_unit CU(
        .clk(clk_1Hz),
        .rst_n,
        .state,
        .opcode,
        .alu_op(ALU_mode)
    );

    logic [3:0] in3, in2, in1, in0;
    seg_four seg_four_inst(
        .clk,
        .rst_n,
        .in3,
        .in2,
        .in1,
        .in0,
        .dp(4'b0000),
        .an,
        .SSD(seg)
    );
    always_ff @(posedge clk_1Hz, negedge rst_n) begin : seg_control // MARK: SEG_CONTROL
        if (!rst_n) begin
            in3 <= 4'b0;
            in2 <= 4'b0;
            in1 <= 4'b0;
            in0 <= 4'b0;
        end else if (opcode == OP_ADD && ALU_state == ALU_Pkg::ALU_DONE) begin
            in3 <= 4'(32'(result / 1000) % 10);
            in2 <= 4'(32'(result / 100) % 10);
            in1 <= 4'(32'(result / 10) % 10);
            in0 <= 4'(result % 10);
        end
    end

    ALU_Pkg::ALU_state_t ALU_state;
    operation_t opcode;
    logic ALU_op;
    logic [1:0] wait_jump; // delay for RAM updating

    wire [`REG_WIDTH - 1:0] imm = command[23:8];
    wire [`REG_ADDR - 1:0] adrA = command[26:24];
    wire [`REG_ADDR - 1:0] adrB = command[23:21];
    wire [`REG_ADDR - 1:0] adrC = command[20:18];

    always_ff @(posedge clk_1Hz, negedge rst_n) begin : Main_FSM // MARK: MAIN
        write_enable <= READ;
        RAM_write_enable <= READ;
        address_write <= 0;
        data_in <= 0;
        wait_jump <= 0;
        if (!rst_n) begin
            address1 <= 0;
            address2 <= 0;
            pc <= 0;
            ALU_op <= 0;
            state <= IDLE;
        end else if (!pause) case (state)
            IDLE: begin
                state <= FETCH;
            end
            FETCH: begin : save_ir
                opcode   <= operation_t'(command[31:27]);
                pc <= pc + 1;
                state    <= EXECUTE;
            end
            EXECUTE: begin //TODO ALU & EXECUTE 協調部分
                case (opcode)
                    OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin : ALU_Operation
                        address_write <= adrA;
                        address1      <= adrB;
                        address2      <= adrC;
                        if (wait_jump == 2'b1) begin
                            ALU_Data1 <= regData1;
                            ALU_Data2 <= regData2;
                            ALU_op <= 1;
                        end else if (ALU_state == ALU_Pkg::ALU_DONE) begin
                            write_enable <= WRITE;
                            data_in <= result;
                            ALU_op <= 0;
                            state <= FETCH;
                        end
                        wait_jump <= wait_jump + 1;
                    end
                    OP_LOADI: begin
                        address_write <= adrA;
                        data_in       <= imm;
                        write_enable  <= WRITE;

                        state <= FETCH;
                    end
                    OP_JMP: begin
                        pc <= imm;

                        if (wait_jump == 2'b1) state <= FETCH;
                        wait_jump <= wait_jump + 1;
                    end
                    OP_JMPR: begin
                        if (wait_jump == 2'b0) begin 
                            address1 <= adrA;
                        end else if (wait_jump == 2'b1) begin 
                            pc <= regData1;
                        end else if (wait_jump == 2'd2) begin 
                            state <= FETCH;
                        end
                    end
                    OP_JNZ: begin
                             if (wait_jump == 2'b0) address1 <= adrA;
                        else if (wait_jump == 2'b1) if (ALU_Data1 != 0) pc <= imm;
                        else if (wait_jump == 2'd2) state <= FETCH;
                        wait_jump <= wait_jump + 1;
                    end

                    OP_JAL: begin
                        pc <= imm;
                        address_write <= adrA;
                        data_in       <= imm;
                        write_enable  <= WRITE;
                        
                        if (wait_jump == 2'b1) state <= FETCH;
                        wait_jump <= wait_jump + 1;
                    end 

                    OP_HALT: begin
                        state <= HALT;
                    end

                    OP_MOV: begin
                        address_write <= adrA;
                        address1      <= adrB;
                        if (wait_jump == 2'b1) begin
                            data_in <= regData1;
                            write_enable <= WRITE;

                            state <= FETCH;
                        end  
                        wait_jump <= wait_jump + 1;
                    end
                    OP_STORE: begin
                        if (wait_jump == 2'b0) begin 
                            address1 <= adrA;
                            RAM_addr <= imm;
                        end else if (wait_jump == 2'b1) begin 
                            RAM_in   <= {16'b0, regData1};
                            RAM_write_enable <= WRITE;
                        end else if (wait_jump == 2'd2)  begin 
                            state <= FETCH;
                        end
                        wait_jump <= wait_jump + 1;
                    end
                    OP_LOAD: begin
                        if (wait_jump == 2'b0) begin 
                            address_write <= adrA;
                            RAM_addr <= imm;
                        end else if (wait_jump == 2'd2) begin 
                            data_in <= `MIN(16'd65535 ,RAM_out);
                            write_enable <= WRITE;
                            state <= FETCH;
                        end
                        wait_jump <= wait_jump + 1;
                    end

                    default: begin
                        state <= FETCH;
                    end
                endcase
            end
            HALT: begin
                state <= HALT; // stay in HALT state
            end
        endcase
    end

    ALU alu_inst (
        .clk(clk_1Hz),
        .rst_n,
        .data1(ALU_Data1),
        .data2(ALU_Data2),
        .mode(ALU_mode),
        .result
    );

    always_ff @(posedge clk_1Hz, negedge rst_n) begin : ALU_Control
        if (!rst_n) begin
            ALU_state <= ALU_Pkg::ALU_IDLE;
        end else if (!pause && ALU_op) case (ALU_state)
            ALU_Pkg::ALU_IDLE: begin
                ALU_state <= ALU_Pkg::ALU_DONE;
            end
            ALU_Pkg::ALU_DONE: begin
                ALU_state <= ALU_Pkg::ALU_IDLE;
            end
        endcase
    end
endmodule
