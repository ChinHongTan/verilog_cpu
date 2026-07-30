`include "top.svh";
`include "ALU_Pkg.sv";
`include "FSM_State_Pkg.sv";

module control_unit(
    input clk,
	input rst_n,
    input state_t state,
    input operation_t opcode,
    output ALU_Pkg::ALU_Mode alu_op
);
    import FSM_State_Pkg::*;
    
    always_ff @(posedge clk, negedge rst_n) begin : Main_FSM
        if (!rst_n) begin
            
        end else case (state)
            IDLE: begin
                
            end
            FETCH: begin
                
            end
            EXECUTE: begin
                case (opcode)
                    OP_ADD: begin
                        alu_op <= ALU_Pkg::ADD;
                    end

                    OP_SUB: begin
                        alu_op <= ALU_Pkg::SUB;
                    end

                    OP_MUL: begin
                        alu_op <= ALU_Pkg::MUL;
                    end

                    OP_DIV: begin
                        alu_op <= ALU_Pkg::DIV;
                    end
                    
                    default: begin
                        alu_op <= alu_op;
                    end
                endcase
                
            end
            default: begin
                
            end
        endcase
    end
endmodule
