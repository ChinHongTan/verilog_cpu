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
    RegData result;                             // data feed into ALU; output from ALU
    RegAddr address1, address2;                 // NEVER be number [3 bit]

    RegData [3:1] data_in;                      // used to send data into register
    RegAddr [3:1] address_write;
    RW [3:1] write_enable; 

    // IR (ROM)
    RAM_Address pc;                             // address of next instruction
    RAM_Data command;                           // instruction register fetched from BRAM
    assign led[7:0] = pc;

    // RAM (data)
    RAM_Address [2:1] RAM_addr;
    RAM_Data [2:1] RAM_in, RAM_out;
    RW [2:1] RAM_write_enable;
    

    bool update_seg;

    RAM_Address out;

    fetch fetch_inst(
        .clk,
        .pc,
        .ir(command)
    );
    wire [4:0] opcode = command[31:27];
    wire [`REG_ADDR - 1:0] adrA = command[26:24];                // first reg
    wire [`REG_ADDR - 1:0] adrB = command[23:21];                // second reg
    wire [`REG_ADDR - 1:0] adrC = command[20:18];                // third reg

    wire [`REG_WIDTH - 1:0] imm = command[23:8];
    wire [`REG_WIDTH - 1:0] branch_imm = command[20:5];
    wire [`ADDR_WIDTH - 1:0] imm_max = overflow_16to8b(imm);
    
    // for imm
    RegData Data1, Data2; // sometimes Data2 is imm, sometimes regData2
    always_comb begin : Decode
        address_write[1] = 3'b0;
        address1      = 3'b0;
        address2      = 3'b0;
        Data1 = 0;
        Data2 = 0;

        case (opcode)
            OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin : ALU_Operation
                Data1 = 0;
                Data2 = 0;
                address_write[1] = adrA;
                address1      = adrB;
                address2      = adrC;
            end

            OP_ADDI, OP_SUBI: begin
                Data1 = regData1;
                Data2 = imm;
                address_write[1] = adrA;
                address1      = adrB;
            end

            OP_MOV: begin
                address_write[1] = adrA;
                address1      = adrB;
            end

            OP_LOAD: begin
                address_write[1] = adrA;
            end

            OP_LOADI: begin
                address_write[1] = adrA;
            end

            OP_LOADR: begin // LOADR R0 R1 ; R0 = BRAM[R1]
                address_write[1] = adrA;
                address1    = adrB;
            end

            OP_STORE: begin
                Data1 = regData1;
                Data2 = imm;
                address1 = adrA;
            end

            OP_STORER: begin 
                address1 = adrA;
                address2 = adrB;
            end

            OP_JMP: begin
                
            end

            OP_JNZ: begin
                address1 = adrA;
            end

            OP_JAL: begin
                address_write[1] = adrA;
            end

            OP_JMPR: begin
                address1 = adrA;
            end

            OP_BEQ, OP_BNE, OP_BLT, OP_BGE: begin
                address1 = adrA;
                address2 = adrB;
            end

            OP_HALT: begin

            end
            
            default: begin

            end

        endcase
    end

    Registers reg_inst(
        .clk,
        .rst_n,
        .address1,
        .address2,
        .data_out1(regData1),
        .data_out2(regData2),

        .write(write_enable[3]),
        .address_write(address_write[3]),
        .data_in(data_in[3])
    );

    
    execute execute_inst(
        .clk,
        .rst_n,
        .Data1,
        .Data2,
        .out,
        .update_seg
    );

    // Data
    memory RAM( // 2 stages delay
        .clk(clk_1Hz),
        .RAM_write_enable(RAM_write_enable[2]), 
        .RAM_addr(RAM_addr[2]),
        .RAM_in(RAM_in[2]),
        .RAM_out(RAM_out[2]),
        .updated()
    );

    logic Z, N, C, V;
    ALU alu_inst (
        .data1(regData1),
        .data2(regData2),
        .mode(ALU_mode),
        .result,
        .Z, .N, .C, .V // Z = zero, N = negative, C = carry, V = overflow
    );

    // flags for Unsigned
    wire equ = Z;
    wire less = N ^ V;
    wire greater_or_equal = ~less;

    always_ff @(posedge clk, negedge rst_n) begin : CU //TODO
        if (!rst_n) begin
            RAM_write_enable[2:1] <= 2'b0;
            write_enable[3:1] <= 3'b0;
        end else begin : Decode_to_Execute
            pc <= pc + 1;
            RAM_write_enable <= (RAM_write_enable << 1);
            write_enable <= (write_enable << 1);

            address_write[3:2] <= address_write[2:1];
            data_in[3:2] <= data_in[2:1];

            RAM_addr[2] <= RAM_addr[1];
            RAM_in[2] <= RAM_in[1];

            case (opcode) // execute stage
                OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_ADDI, OP_SUBI: begin
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                    data_in[1] <= result;
                end
                OP_MOV: begin
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                    data_in[1] <= regData1;
                end

                // Memory
                OP_LOAD: begin
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                end

                OP_LOADI: begin
                    
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                end

                OP_LOADR: begin // LOADR R0 R1 ; R0 = BRAM[R1]
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                end

                OP_STORE: begin
                    RAM_write_enable[2] <= RAM_write_enable[1];
                    RAM_write_enable[1] <= WRITE;
                end

                OP_STORER: begin 
                    RAM_write_enable[2] <= RAM_write_enable[1];
                    RAM_write_enable[1] <= WRITE;
                end

                // Jump and Branch
                OP_JMP: begin
                    pc <= imm_max;
                end
                OP_JNZ: begin
                    if (regData1 != 0) pc <= imm_max;
                end
                OP_JAL: begin
                    pc <= overflow_16to8b(imm);
                    write_enable[3:2] <= write_enable[2:1];
                    write_enable[1] <= WRITE;
                end
                OP_JMPR: begin
                    pc <= overflow_16to8b(regData1);
                end

                OP_BEQ: begin
                    if (equ) pc <= overflow_16to8b(branch_imm);
                end
                OP_BNE: begin
                    if (~equ) pc <= overflow_16to8b(branch_imm);
                end 
                OP_BLT: begin
                    if (less) pc <= overflow_16to8b(branch_imm);
                end 
                OP_BGE: begin
                    if (greater_or_equal) pc <= overflow_16to8b(branch_imm);
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

//module decode(
//    input logic clk,
//    input logic rst_n,
//    input RegAddr address_write, address1, address2,
//    output RegData regData1, regData2
//);
    
//endmodule

module execute(
    input logic clk,
    input logic rst_n,
    input RegData Data1, // regData1
    input RegData Data2, // regData2 or imm
    output RAM_Address out,
    output bool update_seg
);
    ALU_Pkg::ALU_Mode ALU_mode;

    operation_t opcode;

    wire [`ADDR_WIDTH - 1:0] imm_max = overflow_16to8b(Data2);    // saturate to 0xFF  // imm
    always_ff @(posedge clk, negedge rst_n) begin : Main_FSM    // MARK: MAIN
        if (!rst_n) begin
            
        end else begin case (opcode)
            OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin : ALU_Operation
                //ALU_Data1 <= Data1;
                //ALU_Data2 <= Data2;
            end
            OP_ADDI, OP_SUBI: begin
                //ALU_Data1 <= Data1;
                //ALU_Data2 <= Data2; // imm
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
    input logic rst_n,
    input RAM_Address RAM_addr,
    input RAM_Data RAM_in,
    input RW RAM_write_enable,
    output RAM_Data RAM_out,
    output bool updated
);
    RAM_Address RAM_addr_prev;
    always_ff @(posedge clk, negedge rst_n) begin
        updated <= true;
        if (!rst_n) begin 
            RAM_addr_prev <= 0;
        end else if (RAM_write_enable == READ && RAM_addr_prev != RAM_addr) begin
            updated <= false;
            RAM_addr_prev <= RAM_addr;
        end
    end
    // Data
    BRAM RAM(
        .clk,
        .write(RAM_write_enable), 
        .address(RAM_addr),
        .in(RAM_in),
        .out(RAM_out)
    );
endmodule
