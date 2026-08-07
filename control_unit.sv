`include "top.svh"

module control_unit(
    input clk,
	input rst_n,
    input FSM_State_Pkg::state_t state,
    input operation_t opcode,
    output ALU_Pkg::ALU_Mode alu_op
);
    import FSM_State_Pkg::*;
    
    always_ff @(posedge clk, negedge rst_n) begin : ALU_Control
        if (!rst_n) begin
            alu_op <= ALU_Pkg::ADD;
        end else if (state == EXECUTE) begin
            case (opcode)
                OP_ADD, OP_ADDI: begin
                    alu_op <= ALU_Pkg::ADD;
                end

                OP_SUB, OP_SUBI: begin
                    alu_op <= ALU_Pkg::SUB;
                end

                OP_MUL: begin
                    alu_op <= ALU_Pkg::MUL;
                end

                OP_DIV: begin
                    alu_op <= ALU_Pkg::DIV;
                end
                
                default: begin
                    alu_op <= ALU_Pkg::ADD;
                end
            endcase
        end
    end
endmodule
