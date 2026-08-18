module seg_four(
    input clk,          // 100MHz
    input rst_n,
    input [3:0] in3,    // AN3 leftmost
    input [3:0] in2,    // AN2
    input [3:0] in1,    // AN1
    input [3:0] in0,    // AN0 rightmost
	input [3:0] dp,     // 1 : light, 0 : dark
    output reg [3:0] an,// switch between 4 digits
    output wire [7:0] SSD
);

    reg [16:0] clk_div;
    wire scan_clk = clk_div[16]; // highest bit as Clock

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
			clk_div <= 0;
		end else begin
            clk_div <= clk_div + 1;
        end
    end

	// 2-bit counter
    reg [1:0] scan_cnt;
    always @(posedge scan_clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_cnt <= 0;
        end else begin
            scan_cnt <= scan_cnt + 1;
        end
    end

    // control which digit is on
    reg [3:0] current_val;
    always @(*) begin
        if (!rst_n) begin
            an = 4'b1111;
            current_val = 4'b1010;
        end else case(scan_cnt)
            2'b00: begin an = 4'b1110; current_val = in0; end
            2'b01: begin an = 4'b1101; current_val = in1; end
            2'b10: begin an = 4'b1011; current_val = in2; end
            2'b11: begin an = 4'b0111; current_val = in3; end
            default: begin an = 4'b1111; current_val = 4'b0000; end
        endcase
    end

    // segment display decoder
    reg [7:0] SSD_tmp;
    always @(*) begin
        case(current_val)
			4'b0000: SSD_tmp = 8'b00111111; // 0
            4'b0001: SSD_tmp = 8'b00000110; // 1
            4'b0010: SSD_tmp = 8'b01011011; // 2
            4'b0011: SSD_tmp = 8'b01001111; // 3
            4'b0100: SSD_tmp = 8'b01100110; // 4
            4'b0101: SSD_tmp = 8'b01101101; // 5
            4'b0110: SSD_tmp = 8'b01111101; // 6
            4'b0111: SSD_tmp = 8'b00000111; // 7
            4'b1000: SSD_tmp = 8'b01111111; // 8
            4'b1001: SSD_tmp = 8'b01101111; // 9
            default: SSD_tmp = 8'b00000000; // no display
        endcase
		// decimal point control
		SSD_tmp[7] = dp[scan_cnt];
    end
    assign SSD = ~SSD_tmp;
endmodule

