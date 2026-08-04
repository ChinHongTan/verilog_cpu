`include "top.svh"
`include "IR_Pkg.sv"
`include "ALU_Pkg.sv"
`include "FSM_State_Pkg.sv"


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
    logic [7:0] RAM_addr; // pc

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

    logic [31:0] command; // [opcode - 4 bit][reg1Addr - 4 bit][reg2Addr - 4 bit], total 32 bits

    BRAM RAM(
        .clk(clk_1Hz),
        .write(1'b0), // 0:read 1:write
        .address(RAM_addr),
        .in(32'b0),
        .out(command)
    );

    state_t state;
    control_unit CU(
        .clk(clk_1Hz),
        .rst_n,
        .state,
        .opcode,
        .alu_op(ALU_mode)
    );

    seg_four seg_four_inst(
        .clk,
        .rst_n,
        .in3(4'(regData1 % 10)),
        .in2(4'(regData2 % 10)),
        .in1(4'(data_in / 10)),
        .in0(4'(data_in % 10)),
        .dp(4'b0000),
        .an,
        .SSD(seg)
    );

    ALU_Pkg::ALU_state_t ALU_state;
    operation_t opcode;
    logic ALU_op;

    wire isAddr1 = address1[3];
    wire isAddr2 = address2[3];
    always_ff @(posedge clk_1Hz, negedge rst_n) begin : Main_FSM
        write_enable <= READ;
        address_write <= 0;
        data_in <= 0;
        if (!rst_n) begin
            address1 <= 0;
            address2 <= 0;
            RAM_addr <= 0;
            ALU_op <= 0;
            state <= IDLE;
        end else if (!pause) case (state)
            IDLE: begin
                state <= FETCH;
            end
            FETCH: begin : save_ir
                opcode   <= operation_t'(command[11:8]);
                address1 <= command[7:4];
                address2 <= command[3:0];
                RAM_addr <= RAM_addr + 1;
                state    <= EXECUTE;
            end
            EXECUTE: begin //TODO ALU & EXECUTE 協調部分
                case (opcode)
                    OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin : ALU_Operation
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
                    //OP_LOAD: begin

                    //end

                    //OP_STORE: begin

                    //end
                    OP_LOADI: begin
                        led[12] <= 1'b1;
                        if (isAddr1) begin
                            write_enable <= WRITE;
                            address_write <= address1[2:0];
                            if (isAddr2) begin : REG2_IS_ADDRESS
                                data_in <= regData2;
                            end else begin : REG2_IS_NUMBER
                                data_in <= {5'b0, address2[2:0]};
                            end
                        end
                        state <= FETCH;
                    end

                    default: begin
                        state <= FETCH;
                    end
                endcase
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end

    assign ALU_Data1 = (isAddr1) ? regData1 : {5'b0, address1[2:0]};
    assign ALU_Data2 = (isAddr2) ? regData2 : {5'b0, address2[2:0]};
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
