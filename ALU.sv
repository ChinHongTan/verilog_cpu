`include "top.svh"

module ALU 
    import ALU_Pkg::*;
(
    input clk,
    input rst_n,
    input RegData data1, data2,
    input ALU_Mode mode,
    output RegData result
);
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            result <= 8'b0;
        end else begin
            case (mode)
                ADD: result <= data1 + data2;
                SUB: result <= data1 - data2;
                MUL: result <= data1 * data2;
                DIV: result <= data1 / data2;
                default: result <= data1;
            endcase
        end
    end
endmodule

