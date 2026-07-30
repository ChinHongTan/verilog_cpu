`include "top.svh";
`include "IR_Pkg.sv";
`include "ALU_Pkg.sv";
`include "FSM_State_Pkg.sv";


module top(
	input clk,
	input rst_n
);
    import FSM_State_Pkg::*;
    
	logic clk_1Hz;
    ALU_Pkg::ALU_Mode ALU_mode;
	RegData regData1, regData2, result;
    RegAddr address1, address2, address_write;
    logic write_enable;
    logic [7:0] RAM_addr; // pc

    to1Hz to1Hz_inst(
        .clk,
		.rst_n,
		.out(clk_1Hz)
    );

    Registers TODO ( 
        .clk(clk_1Hz),
        .rst_n,
        .address1,
        .address2,
        .data_out1(regData1),
        .data_out2(regData2),

        .write(write_enable), 
        .address_write,
        .data_in(result)
    );

    logic RAM_write_enable;
    logic [15:0] command; // [opcode - 4 bit][reg1Addr - 3 bit][reg2Addr - 3 bit], total 16 bits

    BRAM RAM(
        .clk(clk_1Hz),
        .write(1'b0), // 0:read 1:write
        .address(RAM_addr),
        .in(8'b0),
        .out(command)
    );

    logic [3:0] opcode = command[9:6];

    state_t state;
    control_unit CU(
        .clk,
        .rst_n,
        .state,
        .opcode,
        .alu_op(ALU_mode)
    );

    always_ff @(posedge clk, negedge rst_n) begin : Main_FSM
        if (!rst_n) begin
            state <= IDLE;
        end else case (state)
            IDLE: begin
                state <= FETCH;
            end
            FETCH: begin : save_ir
                opcode   <= command[9:6];
                address1 <= command[5:3];
                address2 <= command[2:0];
                RAM_addr <= RAM_addr + 1;
                state    <= EXECUTE;
            end
            EXECUTE: begin //TODO ALU & EXECUTE 協調部分
                case (opcode)
                    OP_ADD: begin
                        
                    end

                    OP_SUB: begin
                        
                    end

                    OP_MUL: begin
                        
                    end

                    OP_DIV: begin
                        
                    end

                    OP_READ: begin
                        
                    end

                    OP_WRITE: begin
                        
                    end

                    default: begin
                        
                    end
                endcase
                // TODO if (done) state <= FETCH;
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end


    ALU alu_inst (
        .clk(clk_1Hz),
        .rst_n,
        .data1(regData1),
        .data2(regData2),
        .mode(ALU_mode),
        .result
    );
    logic ALU_state;
    always_ff @(posedge clk_1Hz, negedge rst_n) begin : ALU_Control
        address_write <= 0;
        write_enable <= 0;
        if (!rst_n) begin

        end else case (ALU_state)
            0: begin
                ALU_state <= 1;
            end
            1: begin
                write_enable <= 1;
                address_write <= 3'h7;
                ALU_state <= 0;
            end
        endcase
    end
endmodule
