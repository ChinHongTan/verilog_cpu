module seg_four(
    input clk,          // 100MHz
    input rst_n,        
    input [3:0] in3,    // AN3 最左
    input [3:0] in2,    // AN2
    input [3:0] in1,    // AN1
    input [3:0] in0,    // AN0 最右
	input [3:0] dp,     // 切換小數點，1 代表亮
    output reg [3:0] an,// 切換四顆燈
    output wire [7:0] SSD
);

    reg [16:0] clk_div;
    wire scan_clk = clk_div[16]; // 直接拿計數器高位元當 Clock

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
			clk_div <= 0;
		end else begin
            clk_div <= clk_div + 1;
        end
    end

	// 2-bit 計數器，從 0 數到 3 循環，對應四顆燈
    reg [1:0] scan_cnt; 
    always @(posedge scan_clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_cnt <= 0;
        end else begin
            scan_cnt <= scan_cnt + 1;
        end
    end

    // 開關控制器
    reg [3:0] current_val; // 現在這瞬間要翻譯的數字
    always @(*) begin
        if (!rst_n) begin
            an = 4'b1111; // 全滅
            current_val = 4'b1010;
        end else case(scan_cnt)
            2'b00: begin an = 4'b1110; current_val = in0; end // 亮最右邊，吃 in0
            2'b01: begin an = 4'b1101; current_val = in1; end // 亮右二，吃 in1
            2'b10: begin an = 4'b1011; current_val = in2; end // 亮左二，吃 in2
            2'b11: begin an = 4'b0111; current_val = in3; end // 亮最左邊，吃 in3
            default: begin an = 4'b1111; current_val = 4'b0000; end
        endcase
    end

    // 內建七段顯示器解碼字典
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
            default: SSD_tmp = 8'b00000000; // 全滅
        endcase
		// 小數點控制
		SSD_tmp[7] = dp[scan_cnt]; 
    end
    assign SSD = ~SSD_tmp; 
endmodule

