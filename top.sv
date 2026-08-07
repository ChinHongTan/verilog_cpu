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
	RegData regData1, regData2;                 // data fetched from register
    RegData ALU_Data1, ALU_Data2, result;       // data feed into ALU; output from ALU
    RegData data_in;                            // used to send data into register
    RegAddr address_write, address1, address2;  // NEVER be number [3 bit]
    RW write_enable;                            // flag [1 bit], 0 disable, 1 enable

    // IR (ROM)
    RAM_Address pc;                             // address of next instruction
    RAM_Data command;                           // fetched from BRAM
    assign led[7:0] = pc;

    // RAM (data)
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

    // Harvard architecture: instructions and data live in physically separate memories
    // ROM
    BRAM Instruction(
        .clk(clk_1Hz),
        .write(1'b0),   // 0:read 1:write
        .address(pc),   // address
        .in(32'b0),     // value to store
        .out(command)   // value to read
    );

    // Data
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

    ALU_Pkg::ALU_state_t ALU_state;                                 // 1 cycle delay
    operation_t opcode;
    logic ALU_op;
    logic [1:0] wait_jump;                                          // delay for RAM updating

    logic [26:5] current_ir;                                        // instruction register
    wire [`REG_ADDR - 1:0] adrA = current_ir[26:24];                // first reg
    wire [`REG_ADDR - 1:0] adrB = current_ir[23:21];                // second reg
    wire [`REG_ADDR - 1:0] adrC = current_ir[20:18];                // third reg

    wire [`REG_WIDTH - 1:0] imm = current_ir[23:8];                 // label / bram / imm - 16 bit
    wire [`ADDR_WIDTH - 1:0] imm_max = overflow_16to8b(imm);        // saturate to 0xFF

    wire [`REG_WIDTH - 1:0] branch_imm = current_ir[20:5];          // read from BRAM output
    assign led[15:11] = opcode;

    always_ff @(posedge clk_1Hz, negedge rst_n) begin : Main_FSM    // MARK: MAIN
        write_enable <= READ;
        RAM_write_enable <= READ;

        address_write <= 0;
        data_in <= 0;
        if (!rst_n) begin
            address1 <= 0;
            address2 <= 0;
            pc <= 0;
            ALU_op <= 0;
            state <= IDLE;
            current_ir <= 0;

            in3 <= 4'b0;
            in2 <= 4'b0;
            in1 <= 4'b0;
            in0 <= 4'b0;
        end else if (!pause) case (state)
            IDLE: begin
                state <= FETCH;
            end
            FETCH: begin : save_ir
                current_ir <= command[26:5];
                opcode   <= operation_t'(command[31:27]);
                pc <= pc + 1;
                state    <= EXECUTE;
                wait_jump <= 0;
            end
            EXECUTE: begin
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
                    end
                    OP_ADDI, OP_SUBI: begin
                        address_write <= adrA;
                        address1      <= adrB;
                        if (wait_jump == 2'b1) begin
                            ALU_Data1 <= regData1;
                            ALU_Data2 <= imm;
                            ALU_op <= 1;
                        end else if (ALU_state == ALU_Pkg::ALU_DONE) begin
                            write_enable <= WRITE;
                            data_in <= result;
                            ALU_op <= 0;
                            state <= FETCH;
                        end
                    end
                    OP_MOV: begin
                        address_write <= adrA;
                        address1      <= adrB;
                        if (wait_jump == 2'b1) begin
                            data_in <= regData1;
                            write_enable <= WRITE;

                            state <= FETCH;
                        end  
                    end

                    OP_LOAD: begin
                        if (wait_jump == 2'b0) begin 
                            address_write <= adrA;
                            RAM_addr <= imm_max;
                        end else if (wait_jump == 2'd2) begin 
                            data_in <= RAM_out[15:0];
                            write_enable <= WRITE;
                            state <= FETCH;
                        end
                    end

                    OP_LOADI: begin
                        address_write <= adrA;
                        data_in       <= imm;
                        write_enable  <= WRITE;

                        state <= FETCH;
                    end

                    OP_LOADR: begin // LOADR R0 R1 ; R0 = BRAM[R1]
                        if (wait_jump == 2'b0) begin 
                            address_write <= adrA;
                            address1 <= adrB;
                        end else if (wait_jump == 2'd1) begin 
                            RAM_addr <= overflow_16to8b(regData1);
                        end else if (wait_jump == 2'd3) begin 
                            data_in <= RAM_out[15:0];
                            write_enable <= WRITE;
                            state <= FETCH;
                        end
                    end

                    OP_STORE: begin
                        if (imm >= 16'd65_500) begin
                            if (wait_jump == 2'b0) begin 
                                address1 <= adrA;
                            end else if (wait_jump == 2'b1) begin : seg_control
                                in3 <= 4'(32'(regData1 / 1000) % 10);
                                in2 <= 4'(32'(regData1 / 100) % 10);
                                in1 <= 4'(32'(regData1 / 10) % 10);
                                in0 <= 4'(regData1 % 10);

                                state <= FETCH;
                            end
                        end else if (wait_jump == 2'b0) begin 
                            address1 <= adrA;
                        end else if (wait_jump == 2'b1) begin 
                            RAM_addr <= imm_max;
                            RAM_in   <= {16'b0, regData1};
                            RAM_write_enable <= WRITE;
                        end else if (wait_jump == 2'd2)  begin 
                            state <= FETCH;
                        end
                    end

                    OP_STORER: begin 
                        if (wait_jump == 2'b0) begin 
                            address1 <= adrA;
                            address2 <= adrB;
                        end else if (wait_jump == 2'd1) begin 
                            RAM_addr <= overflow_16to8b(regData2);
                            RAM_in   <= {16'b0, regData1};
                            RAM_write_enable <= WRITE;
                        end else if (wait_jump == 2'd2) begin 
                            state <= FETCH;
                        end
                    end

                    OP_JMP: begin
                        pc <= imm_max;

                        if (wait_jump == 2'b1) state <= FETCH;
                    end
                    OP_JNZ: begin
                             if (wait_jump == 2'b0) address1 <= adrA;
                        else if (wait_jump == 2'b1) begin if (regData1 != 0) pc <= imm_max; end
                        else if (wait_jump == 2'd2) state <= FETCH;
                    end
                    OP_JAL: begin
                        if (wait_jump == 2'b0) begin
                            address_write <= adrA;
                            data_in       <= 16'(pc);
                            write_enable  <= WRITE;
                            pc            <= overflow_16to8b(imm);
                        end else if (wait_jump == 2'd1) begin
                            state <= FETCH;
                        end
                    end 
                    OP_JMPR: begin
                        if (wait_jump == 2'b0) begin 
                            address1 <= adrA;
                        end else if (wait_jump == 2'b1) begin 
                            pc <= overflow_16to8b(regData1);
                        end else if (wait_jump == 2'd2) begin 
                            state <= FETCH;
                        end
                    end


                    OP_BEQ, OP_BNE, OP_BLT, OP_BGE: begin
                        if (wait_jump == 2'b0) begin 
                            address1 <= adrA;
                            address2 <= adrB;
                        end else if (wait_jump == 2'd1) begin 
                            if ((opcode == OP_BEQ && regData1 == regData2) ||
                                (opcode == OP_BNE && regData1 != regData2) ||
                                (opcode == OP_BLT && regData1 <  regData2) ||
                                (opcode == OP_BGE && regData1 >= regData2)
                            ) begin 
                                pc <= overflow_16to8b(branch_imm);
                            end
                        end else if (wait_jump == 2'd2) begin 
                            state <= FETCH;
                        end
                    end
                    
                    OP_HALT: begin
                        state <= HALT;
                    end

                    default: begin
                        state <= FETCH;
                    end
                endcase
                wait_jump <= wait_jump + 1;
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
