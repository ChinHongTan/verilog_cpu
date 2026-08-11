`include "top.svh"

module pipeline(
	input clk,
    input [15:0] sw,
    output logic [15:0] led,
    output [7:0] seg,
    output [3:0] an
);
    wire rst_n = sw[0];
    bool updated;
    wire freeze = sw[15];
    bool pause;
    bool halt;
    assign pause = bool'(~updated || freeze);

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

    RegData [2:1] data_in;                      // used to send data into register
    RegAddr [2:0] address_write;
    RW [2:0] write_enable; 

    // IR (ROM)
    RAM_Address pc;                             // address of next instruction
    RAM_Data command;                           // instruction register fetched from BRAM
    assign led[7:0] = pc;

    // RAM (data)
    // 1: current out, 2: previous out for reg
    RAM_Address RAM_addr;
    RAM_Data RAM_in;
    RW [1:0] RAM_write_enable;
    
    bool [1:0] load;
    bool update_seg;

    Registers reg_inst(
        .clk,
        .rst_n,
        .address1,
        .address2,
        .data_out1(regData1),
        .data_out2(regData2),

        .write(write_enable[2]),
        .address_write(address_write[2]),
        .data_in(data_in[2])
    );

    fetch fetch_inst(
        .clk,
        .pc,
        .ir(command)
    );
    operation_t opcode;
    assign opcode = operation_t'(command[31:27]); // current operation in DECODE

    // MARK: Decode addr
    always_ff @(posedge clk or negedge rst_n) begin : decode_stage
        if (!rst_n) begin
            address_write[0] <= 3'b0;         // first reg
            address1         <= 3'b0;         // second reg
            address2         <= 3'b0;         // third reg
        end else begin
            address_write[0] <= command[26:24];         // first reg
            address1         <= command[23:21];         // second reg
            address2         <= command[20:18];         // third reg
        end
    end

    RegData imm;
    assign imm = command[17:2]; // immediate value

    // MARK: ALU
    logic Z, N, C, V;
    always_comb begin : ALU_Control
        case (opcode)
            OP_ADD, OP_ADDI: begin
                ALU_mode = ALU_Pkg::ADD;
            end

            OP_SUB, OP_SUBI: begin
                ALU_mode = ALU_Pkg::SUB;
            end

            OP_MUL: begin
                ALU_mode = ALU_Pkg::MUL;
            end

            OP_DIV: begin
                ALU_mode = ALU_Pkg::DIV;
            end
            
            default: begin : comparing_signal
                ALU_mode = ALU_Pkg::SUB;
            end
        endcase
    end
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

    // MARK: Decode stage
    logic jump_condition;
    RegData Data1, Data2;
    execute_mode_t execute_mode;
    always_comb begin : decode_control
        Data1 = 0;
        Data2 = 0;
        jump_condition = false;
        write_enable[0] = READ;
        RAM_write_enable[0] = READ;
        execute_mode = NONE;
        load[0] = false;
        case (opcode) // execute stage
            OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin
                Data1 = regData1;
                Data2 = regData2;
                write_enable[0] = WRITE;
                execute_mode = CALC;
            end
            OP_ADDI, OP_SUBI: begin
                Data1 = regData1;
                Data2 = imm;
                write_enable[0] = WRITE;
                execute_mode = CALC;
            end

            OP_STORE: begin
                Data1 = regData1;
                Data2 = imm;
                RAM_write_enable[0] = WRITE;
                execute_mode = STORE;
            end

            OP_STORER: begin 
                RAM_write_enable[0] = WRITE;
                execute_mode = STORER;
            end

            OP_MOV: begin
                write_enable[0] = WRITE;
                execute_mode = MOV;
            end

            // Memory
            OP_LOAD: begin
                write_enable[0] = WRITE;
                load[0] = true;
            end

            OP_LOADI: begin
                write_enable[0] = WRITE;
            end

            OP_LOADR: begin // LOADR R0 R1 ; R0 = BRAM[R1]
                write_enable[0] = WRITE;
                load[0] = true;
            end

            // Jump and Branch
            OP_JMP: begin
                Data1 = imm;
                jump_condition = true;
            end
            OP_JNZ: begin
                Data1 = imm;
                jump_condition = (regData1 != 0);
            end
            OP_JAL: begin
                Data1 = imm;
                jump_condition = true;
                write_enable[0] = WRITE;
            end
            OP_JMPR: begin
                Data1 = regData1;
                jump_condition = true;
            end

            OP_BEQ: begin
                Data1 = imm;
                jump_condition = equ;
            end
            OP_BNE: begin
                Data1 = imm;
                jump_condition = ~equ;
            end 
            OP_BLT: begin
                Data1 = imm;
                jump_condition = less;
            end 
            OP_BGE: begin
                Data1 = imm;
                jump_condition = greater_or_equal;
            end
            default: begin
            end
        endcase
    end

    
    logic [1:0] after_jump;
    // MARK: Execute stage
    always_ff @(posedge clk, negedge rst_n) begin : Execute_Stage
        if (!rst_n) begin
            pc <= 0;

            // write enable signals 
            RAM_write_enable[1] <= READ;
            write_enable[1] <= READ;

            // signals for RAM
            RAM_addr <= 0;
            RAM_in <= 0;

            // signals for REG
            data_in[1] <= 0;
            address_write[1] <= 0;

        end else if (!pause) begin : Decode_to_Execute
            pc <= pc + 1;

            // write enable signals 
            RAM_write_enable[1] <= RAM_write_enable[0];
            write_enable[1] <= write_enable[0];

            // signals for RAM
            RAM_addr <= 0;
            RAM_in <= 0;

            // signals for REG
            data_in[1] <= 0;
            address_write[1] <= address_write[0];

            load[1] <= load[0];
            case (execute_mode) // execute stage
                CALC: begin
                    data_in[1] <= result;
                end
                
                MOV: begin
                    data_in[1] <= Data1; // RegData1
                end

                STORE: begin
                    if (Data2 >= 16'd65_500) begin : update_display
                        update_seg <= true;
                        write_enable[1] <= READ;
                    end else begin 
                        RAM_in <= {16'b0, Data2}; // imm
                    end
                end

                STORER: begin 
                    RAM_in <= {16'b0, Data2}; // RegData2
                end

                HALT: begin
                    halt <= true;
                end

                NONE: begin
                    if (jump_condition) begin
                        pc <= overflow_16to8b(Data1); // imm or RegData1
                        //TODO change next ir to nop
                    end
                end
                default: begin
                    if (jump_condition) begin
                        pc <= overflow_16to8b(Data1); // imm or RegData1
                    end
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
            in3 <= 4'((regData1 / 1000) % 10);
            in2 <= 4'((regData1 / 100) % 10);
            in1 <= 4'((regData1 / 10) % 10);
            in0 <= 4'(regData1 % 10);
        end
    end

    // MARK: RAM Data
    memory RAM( // 2 stages delay
        .clk(clk_1Hz),
        .rst_n,
        .RAM_write_enable(RAM_write_enable[1]), 
        .RAM_addr,
        .RAM_in,
        .updated,

        // signals for registers
        .write_enable_mem(write_enable[1]),
        .write_enable_wb(write_enable[2]), 
        .address_write_mem(address_write[1]),
        .address_write_wb(address_write[2]),
        .data_in_mem(data_in[1]),
        .data_in_wb(data_in[2]),

        .load(load[1]), // Whether the data_in is from mem (LOAD/LOADR)
        .pause
    );
endmodule

module fetch (
    input logic clk,
    input RAM_Address pc,

    output logic [31:0] ir
);
    BRAM Instruction(
        .clk,
        .write(READ),   // 0:read 1:write
        .address(pc),   // address
        .in(32'b0),     // value to store
        .out(ir)        // value to read
    );
endmodule

module memory(
    input logic clk,
    input logic rst_n,
    input RAM_Address RAM_addr,
    input RAM_Data RAM_in,
    input RW RAM_write_enable,
    output bool updated,

    // signals for registers
    input RW write_enable_mem,
    output RW write_enable_wb, 
    input RegAddr address_write_mem,
    output RegAddr address_write_wb,
    input RegData data_in_mem,
    output RegData data_in_wb,

    input bool load, // Whether the data_in is from mem (LOAD/LOADR)
    input bool pause
);
    RAM_Data RAM_out;

    RAM_Address RAM_addr_prev;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin 
            updated <= false;
            RAM_addr_prev <= 0;
            write_enable_wb <= READ;
            address_write_wb <= 0;
            data_in_wb <= 0;
        end else if (RAM_write_enable == READ && RAM_addr_prev != RAM_addr) begin
            updated <= false;
            RAM_addr_prev <= RAM_addr;
        end else begin : normal_run
            updated <= true;

            address_write_wb <= address_write_mem;
            if (load == true) begin
                write_enable_wb <= WRITE;
                data_in_wb <= RAM_out[15:0];
            end else begin : simply_pass_data
                write_enable_wb <= write_enable_mem;
                data_in_wb <= data_in_mem;
            end
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
