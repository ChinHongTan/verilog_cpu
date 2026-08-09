`include "top.svh"

module pipeline(
	input clk,
    input [15:0] sw,
    output logic [15:0] led,
    output [7:0] seg,
    output [3:0] an
);
    
    wire rst_n = sw[0];
    wire pause = sw[15];

	logic clk_1Hz;
    to1Hz to1Hz_inst(
        .clk,
		.rst_n,
		.out(clk_1Hz)
    );
    ALU_Pkg::ALU_Mode ALU_mode;

    // Registers
	RegData regData1, regData2;                 // data fetched from register
    RegData ALU_Data1, ALU_Data2, result;       // data feed into ALU; output from ALU
    RegData data_in;                            // used to send data into register
    RegAddr address_write, address1, address2;  // NEVER be number [3 bit]

    // IR (ROM)
    RAM_Address pc;                             // address of next instruction
    RAM_Data command;                           // fetched from BRAM
    assign led[7:0] = pc;

    // RAM (data)
    RAM_Address RAM_addr;
    RAM_Data RAM_in, RAM_out;

    bool update_seg;

    RAM_Address out;

    logic [31:0] current_ir;                                        // instruction register
    fetch fetch_inst(
        .clk,
        .rst_n,
        .pc,
        .ir(current_ir)
    );
    wire [4:0] opcode = current_ir[31:24];

    decode decode_inst(
        .clk,
        .rst_n,
        .address_write,
        .address1,
        .address2,
        .regData1,
        .regData2
    );
    Registers reg_inst(
        .clk,
        .rst_n,
        .address1,
        .address2,
        .data_out1(regData1),
        .data_out2(regData2),

        .write(write_enable[3]),
        .address_write,
        .data_in
    );

    RegData Data1, Data2; // sometimes Data2 is imm, sometimes regData2
    execute execute_inst(
        .clk,
        .rst_n,
        .Data1,
        .Data2,
        .out,
        .update_seg
    );

    // Data
    BRAM RAM(
        .clk(clk_1Hz),
        .write(RAM_write_enable[2]), 
        .address(RAM_addr),
        .in(RAM_in),
        .out(RAM_out)
    );

    RW [2:1] RAM_write_enable;
    RW [3:1] write_enable; 

    wire [`REG_WIDTH - 1:0] imm = current_ir[23:8];
    always_ff @(posedge clk, negedge rst_n) begin : CU //TODO
        if (!rst_n) begin
            RAM_write_enable[2:1] <= 2'b0;
            write_enable[3:1] <= 3'b0;
        end else begin : Decode_to_Execute
            pc <= pc + 1;
            RAM_write_enable <= (RAM_write_enable << 1);
            write_enable <= (write_enable << 1);

            case (opcode)
                OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin : ALU_Operation
                    Data1 <= regData1;
                    Data2 <= regData2;
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                end
                OP_ADDI, OP_SUBI: begin
                    Data1 <= regData1;
                    Data2 <= imm;
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                end
                OP_MOV: begin
                    Data1 <= 0;
                    Data2 <= 0;
                    
                end

                OP_LOAD: begin
                    Data1 <= 0;
                    Data2 <= 0;
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                end

                OP_LOADI: begin
                    Data1 <= 0;
                    Data2 <= 0;
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                end

                OP_LOADR: begin // LOADR R0 R1 ; R0 = BRAM[R1]
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                end

                OP_STORE: begin
                    Data1 <= regData1;
                    Data2 <= imm;
                    RAM_write_enable[2] <= RAM_write_enable[1];
                    RAM_write_enable[1] <= WRITE;
                end

                OP_STORER: begin 
                    RAM_write_enable[2] <= RAM_write_enable[1];
                    RAM_write_enable[1] <= WRITE;
                end

                OP_JMP: begin
                    
                end
                OP_JNZ: begin
                    
                end
                OP_JAL: begin
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                end
                OP_JMPR: begin
                    
                end

                OP_BEQ, OP_BNE, OP_BLT, OP_BGE: begin
                    
                end
                
                OP_HALT: begin
                    
                end

                default: begin
                end
        endcase
        end
    end

    logic [3:0] in3, in2, in1, in0;
    seg_four seg_four_inst(
        .clk,
        .rst_n,
        .in3,
        .in2,
        .in1,
        .in0,
        .dp(4'b0000),
        .an,
        .SSD(seg)
    );

    always_ff @(posedge clk_1Hz, negedge rst_n) begin : seg_control // MARK: SEG_CONTROL
        if (!rst_n) begin
            in3 <= 4'b0;
            in2 <= 4'b0;
            in1 <= 4'b0;
            in0 <= 4'b0;
        end else if (update_seg == true) begin
            in3 <= 4'(32'(regData1 / 1000) % 10);
            in2 <= 4'(32'(regData1 / 100) % 10);
            in1 <= 4'(32'(regData1 / 10) % 10);
            in0 <= 4'(regData1 % 10);
        end
    end

endmodule

module fetch (
    input logic clk,
    input logic rst_n,
    input RAM_Address pc,

    output logic [31:0] ir
);
    BRAM Instruction(
        .clk,
        .write(1'b0),   // 0:read 1:write
        .address(pc),   // address
        .in(32'b0),     // value to store
        .out(ir)        // value to read
    );
endmodule

module decode(
    input logic clk,
    input logic rst_n,
    input RegAddr address_write, address1, address2,
    output RegData regData1, regData2
);
    
endmodule

module execute(
    input logic clk,
    input logic rst_n,
    input RegData Data1, // regData1
    input RegData Data2, // regData2 or imm
    output RAM_Address out,
    output bool update_seg
);
    RegData ALU_Data1, ALU_Data2, result;       // data feed into ALU; output from ALU
    ALU_Pkg::ALU_Mode ALU_mode;

    operation_t opcode;
    bool ALU_op;
    ALU alu_inst (
        .clk(clk),
        .rst_n,
        .data1(ALU_Data1),
        .data2(ALU_Data2),
        .mode(ALU_mode),
        .result
    );

    wire [`ADDR_WIDTH - 1:0] imm_max = overflow_16to8b(Data2);    // saturate to 0xFF  // imm
    always_ff @(posedge clk, negedge rst_n) begin : Main_FSM    // MARK: MAIN
        if (!rst_n) begin
            
        end else begin case (opcode)
            OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin : ALU_Operation
                ALU_Data1 <= Data1;
                ALU_Data2 <= Data2;
                ALU_op <= true;
            end
            OP_ADDI, OP_SUBI: begin
                ALU_Data1 <= Data1;
                ALU_Data2 <= Data2; // imm
                ALU_op <= true;
            end
            OP_MOV: begin
                
            end

            OP_LOAD: begin
                
            end

            OP_LOADI: begin
                
            end

            OP_LOADR: begin // LOADR R0 R1 ; R0 = BRAM[R1]
                out <= overflow_16to8b(Data1);
            end

            OP_STORE: begin
                if (Data2 >= 16'd65_500) begin : update_display
                    update_seg <= true;
                end else begin 
                    out <= imm_max;
                end
            end

            OP_STORER: begin 
                out <= overflow_16to8b(Data2);
            end

            OP_JMP: begin
                out <= imm_max;  
            end
            OP_JNZ: begin
                if (Data1 != 0) out <= imm_max;
            end
            OP_JAL: begin
                out            <= overflow_16to8b(Data2); // imm
            end
            OP_JMPR: begin
                out <= overflow_16to8b(Data1);
            end

            OP_BEQ, OP_BNE, OP_BLT, OP_BGE: begin
                if ((opcode == OP_BEQ && Data1 == Data2) ||
                    (opcode == OP_BNE && Data1 != Data2) ||
                    (opcode == OP_BLT && Data1 <  Data2) ||
                    (opcode == OP_BGE && Data1 >= Data2)
                ) begin 
                    out <= overflow_16to8b(Data2); // imm
                end
            end
            
            OP_HALT: begin
                
            end

            default: begin
            end
        endcase
        end
    end
endmodule

module memory(
    input logic clk,
    input RAM_Address RAM_addr,
    input RAM_Data RAM_in,
    input RW RAM_write_enable,
    output RAM_Data RAM_out
);
    // Data
    BRAM RAM(
        .clk,
        .write(RAM_write_enable), 
        .address(RAM_addr),
        .in(RAM_in),
        .out(RAM_out)
    );
endmodule
