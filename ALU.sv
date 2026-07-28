`include "top.svh"
`include "ALU_Pkg.sv"


module ALU 
    import ALU_Pkg::*;
(
    input clk,
    input rst_n,
    input RegData reg1, reg2,
    input ALU_Mode mode,
    output RegData result
);
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            result <= 8'b0;
        end else begin
            case (mode)
                ADD: result <= reg1 + reg2;
                SUB: result <= reg1 - reg2;
                MUL: result <= reg1 * reg2;
                DIV: result <= reg1 / reg2;
                default: result <= reg1;
            endcase
        end
    end
endmodule
