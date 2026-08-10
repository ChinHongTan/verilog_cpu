`include "top.svh"

module ALU 
    import ALU_Pkg::*;
(
    input RegData data1, data2,
    input ALU_Mode mode,
    output RegData result,
    output logic Z, N, C, V // Z = zero, N = negative, C = carry, V = overflow
); // ARM / RISC-V 
    RegData out_comb, out_seq;
    always_comb begin
        C = 1'b0;
        V = 1'b0;
        case (mode)
            ADD: begin {C, out_comb} = data1 + data2; V = (data1[15] == data2[15]) && (out_comb[15] != data1[15]); end
            SUB: begin {C, out_comb} = data1 - data2; V = (data1[15] != data2[15]) && (out_comb[15] != data1[15]); end
            MUL: out_comb = data1 * data2; //TODO ZNCV
            DIV: out_comb = (data2 == 0) ? 16'hFFFF : data1 / data2; //TODO ZNCV
            default: {C, out_comb} = data1 - data2; 
        endcase
    end

    assign result = (mode == DIV) ? out_seq : out_comb;
    assign Z = (result == 16'b0);
    assign N = out_comb[15];

    // TODO not supported now 
    //always_ff @(posedge clk, negedge rst_n) begin : div
    //    if (!rst_n) begin
    //        out_seq <= 16'b0;
    //    end else if (mode == DIV) begin
    //        out_seq <= data1 / data2;
    //    end
    //end
endmodule
