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
	RegData regData1, regData2;
    RegData ALU_Data1, ALU_Data2, result;
    RegAddrNum address1, address2;
    RegAddr address_write; // NEVER be number
    RW write_enable;
    logic [7:0] pc, RAM_addr; 

    to1Hz to1Hz_inst(
        .clk,
		.rst_n,
		.out(clk_1Hz)
    );
    //assign clk_1Hz = clk;

    RegData data_in;
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

    RAM_Address command; // [opcode - 4 bit][reg1Addr - 4 bit][reg2Addr - 4 bit], total 32 bits
    RAM_Address RAM_in, RAM_out;
    RW RAM_write_enable;

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
            in3 <= 4'(result / 1000 % 10);
            in2 <= 4'(result / 100 % 10);
            in1 <= 4'(result / 10 % 10);
            in0 <= 4'(result % 10);
        end
    end

    ALU_Pkg::ALU_state_t ALU_state;
    operation_t opcode;
    logic ALU_op;
    logic wait_jump; // 1 clk delay for RAM updating
    wire RAM_updated = (wait_jump == 1'b1);

    wire isAddr1 = address1[3];
    wire isAddr2 = address2[3];
    assign ALU_Data1 = (isAddr1) ? regData1 : {5'b0, address1[2:0]};
    assign ALU_Data2 = (isAddr2) ? regData2 : {5'b0, address2[2:0]};

    assign led[11:0] = {opcode, address1, address2}; // show current ir
    always_ff @(posedge clk_1Hz, negedge rst_n) begin : Main_FSM // MARK: MAIN
        led[15:12] <= 4'b0;
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
                led[15] <= 1'b1;
                opcode   <= operation_t'(command[11:8]);
                address1 <= command[7:4];
                address2 <= command[3:0];
                pc <= pc + 1;
                state    <= EXECUTE;
            end
            EXECUTE: begin //TODO ALU & EXECUTE 協調部分
                led[14] <= 1'b1;
                case (opcode)
                    OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin : ALU_Operation
                        led[13] <= 1'b1;
                        if (ALU_state == ALU_Pkg::ALU_DONE) begin
                            if (isAddr1) begin
                                write_enable <= WRITE;
                                address_write <= address1[2:0];
                                data_in <= result;
                            end
                            ALU_op <= 0;
                            state <= FETCH;
                        end else begin
                            ALU_op <= 1;
                        end
                    end
                    OP_LOADI: begin
                        led[12] <= 1'b1;
                        if (isAddr1) begin
                            write_enable <= WRITE;
                            address_write <= address1[2:0];
                            data_in <= regData2;
                        end
                        state <= FETCH;
                    end
                    OP_JMP: begin
                        pc <= ALU_Data1;
                        if (RAM_updated) state <= FETCH;
                        else wait_jump <= wait_jump + 1;
                    end
                    OP_JNZ: begin
                        if (regData1 != 0) begin
                            pc <= ALU_Data2;
                        end
                        if (RAM_updated) state <= FETCH;
                        else wait_jump <= wait_jump + 1;
                    end
                    OP_HALT: begin
                        state <= HALT;
                    end
                    OP_STORE: begin
                        RAM_in   <= {24'b0, regData1}; // data    to store
                        RAM_addr <= regData2;          // RAM address to store
                        RAM_write_enable <= WRITE;

                        if (RAM_updated) state <= FETCH;
                        else wait_jump <= wait_jump + 1;
                    end
                    OP_LOAD: begin
                        if (isAddr1) begin
                            address_write <= address1[2:0]; // reg to load
                            RAM_addr <= regData2;           // RAM address to load
                            if (RAM_updated) begin : Wait_Load_RAM
                                data_in <= RAM_out[7:0];    // data to load
                                write_enable <= WRITE;

                                state <= FETCH;
                            end else begin 
                                wait_jump <= wait_jump + 1;
                            end 
                        end else begin
                            state <= FETCH;
                        end
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
