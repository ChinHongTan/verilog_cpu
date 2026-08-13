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
    bool jal;
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
    RegData Data1, Data2;
    ALU alu_inst (
        .data1(Data1),
        .data2(Data2),
        .mode(ALU_mode),
        .result,
        .Z, .N, .C, .V // Z = zero, N = negative, C = carry, V = overflow
    );
    // flags for Unsigned
    wire equ = Z;
    wire less = N ^ V;
    wire greater_or_equal = ~less;
	RegData Data1_de, Data2_de;

	execute_mode_t execute_mode;
	logic jump_condition;
	decode decode_inst (
		.clk,
		.rst_n,
		.command,
		.regData1, .regData2,
		.equ, .less, .greater_or_equal,
		
		.load_de(load[0]),
		.write_enable_de(write_enable[0]),
		.RAM_write_enable_de(RAM_write_enable[0]),
		.Data1_de, .Data2_de,
		.address1, .address2,
		.address_write_de(address_write[0]),

		.execute_mode,
		.jump_condition,
        .jal
	);

	//TODO: add forwarding for load instruction
	always_comb begin : forwarding_multiplexer //MARK: Forwarding
		Data1 = Data1_de;
		Data2 = Data2_de;
        case (address1)
            address_write[1]: if (write_enable[1] == WRITE) begin Data1 = data_in[1]; end // execute stage
            address_write[2]: if (write_enable[2] == WRITE) begin Data1 = data_in[2]; end // write back stage
            default:                                        begin Data1 = Data1_de;   end
        endcase

        case (address2)
			address_write[1]: if (write_enable[1] == WRITE) begin Data2 = data_in[1]; end
            address_write[2]: if (write_enable[2] == WRITE) begin Data2 = data_in[2]; end
            default:                                        begin Data2 = Data2_de;   end
        endcase
    end
    
    logic [1:0] after_jump_lock;
    // MARK: Execute stage
    always_ff @(posedge clk, negedge rst_n) begin : Execute_Stage
        update_seg <= false;
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
            load[1] <= load[0];

            // signals for REG
            data_in[1] <= 0;
            address_write[1] <= address_write[0];

            if (after_jump_lock != 2'b00) begin : solve_control_hazard
                if (after_jump_lock == 2'b1) begin
                    pc <= pc; // don't jump
                end
                after_jump_lock <= after_jump_lock + 1;

                // block the signals
                RAM_write_enable[1] <= READ;
                write_enable[1] <= READ;

                RAM_addr <= 0;
                RAM_in <= 0;

                data_in[1] <= 0;
                address_write[1] <= 0;
            end else case (execute_mode) // execute stage
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

                JUMP: begin
                    if (jump_condition) begin
                        pc <= overflow_16to8b(Data1); // imm or RegData1
                        after_jump_lock <= 2'b01;
                        //TODO change next ir to nop
                    end
                    if (jal) begin
                        data_in[1] <= pc + 1; // store the next instruction address into reg
                    end
                end
                default: begin
                    if (jump_condition) begin
                        pc <= overflow_16to8b(Data1); // imm or RegData1
                        after_jump_lock <= 2'b01;
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
		//.RAM_out,
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
