module to1Hz(
    input clk,
    input rst_n,
    output logic out
);
    logic [26:0] count;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            out <= 0;
        end else if (count >= 49_999_999) begin
            count <= 0;
            out <= 1;
        end else begin
            count <= count + 1;
            out <= 0;
        end
    end
endmodule
