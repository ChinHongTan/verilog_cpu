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

	logic clk_main;
    to1Hz to1Hz_inst(
        .clk,
        .rst_n,
        .out(clk_main)
    );
    // assign clk_main = clk;
    ALU_Pkg::ALU_Mode ALU_mode;

    // Registers
	RegData regData1, regData2;                 // data fetched from register
    RegData result;                             // data feed into ALU; output from ALU
    RegAddr address1, address2;                 // NEVER be number [3 bit]

    RegData [2:1] data_in /*verilator split_var*/;   // used to send data into register
    RegAddr [2:0] address_write /*verilator split_var*/;
    RW [2:0] write_enable /*verilator split_var*/;

    // IR (ROM)
    RAM_Address pc;                             // address of next instructionAM
    assign led[7:0] = pc;

    // RAM (data)
    RAM_Data command;                           // instruction register fetched from BR
    // 1: current out, 2: previous out for reg
    RAM_Address RAM_addr;
    RAM_Data RAM_in;
    RW [1:0] RAM_write_enable /*verilator split_var*/;

    bool [1:0] load /*verilator split_var*/;
    bool update_seg;

    Registers reg_inst(
        .clk(clk_main),
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
        .clk(clk_main),
        .pc,
        .ir(command)
    );

    // MARK: ALU
    logic Z, N, C, V;
    
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
    wire less = C;
    wire greater_or_equal = ~less;
	RegData Data1_de, Data2_de;

	execute_mode_t execute_mode;
	logic jump_condition;
	RegData jump_target;
	bool jump_reg;
    logic clear_op;
    bool read1, read2;
	decode decode_inst (
		.clk(clk_main),
		.rst_n,
		.command,
		.regData1, .regData2,
        .clear_op,
		.equ, .less, .greater_or_equal,
		
		.load_de(load[0]),
		.write_enable_de(write_enable[0]),
		.RAM_write_enable_de(RAM_write_enable[0]),
		.Data1_de, .Data2_de,
		.jump_target_de(jump_target),
		.jump_reg,
		.address1, .address2,
        .read1, .read2,
		.address_write_de(address_write[0]),
        .ALU_mode,
		.execute_mode,
		.jump_condition,
        .jal
	);

	//TODO: add forwarding for load instruction
	always_comb begin : forwarding_multiplexer //MARK: Forwarding
        Data1 = Data1_de;
        Data2 = Data2_de;
        if (!read1) begin
            Data1 = Data1_de;
        end else if (address1 == address_write[1] && write_enable[1] == WRITE) begin 
            Data1 = data_in[1]; // execute stage
        end else if (address1 == address_write[2] && write_enable[2] == WRITE) begin 
            Data1 = data_in[2]; // write back stage
        end

        if (!read2) begin
            Data2 = Data2_de;
        end else if (address2 == address_write[1] && write_enable[1] == WRITE) begin 
            Data2 = data_in[1]; 
        end else if (address2 == address_write[2] && write_enable[2] == WRITE) begin 
            Data2 = data_in[2]; 
        end
    end

    logic [3:0] in3, in2, in1, in0;
    logic after_jump_lock;
    // MARK: Execute stage
    always_ff @(posedge clk_main, negedge rst_n) begin : Execute_Stage
        update_seg <= false;
        clear_op <= false;
        if (!rst_n) begin
            pc <= 0;

            in3 <= 4'b0;
            in2 <= 4'b0;
            in1 <= 4'b0;
            in0 <= 4'b0;

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

            if (after_jump_lock != 0) begin : solve_control_hazard
                pc <= pc; // don't jump
                after_jump_lock <= after_jump_lock + 1;

                // block the signals
                RAM_write_enable[1] <= READ;
                write_enable[1] <= READ;

                RAM_addr <= 0;
                RAM_in <= 0;

                data_in[1] <= 0;
                address_write[1] <= 0;
            end else case (execute_mode) // execute stage
                NONE: begin
                end

                CALC: begin
                    data_in[1] <= result;
                end
                
                MOV: begin
                    data_in[1] <= Data1; // RegData1
                end

                STORE: begin
                    if (Data2 >= 16'd65_500) begin : update_display //TODO throw into ALU
                        update_seg <= true;
                        RAM_write_enable[1] <= READ;

                        in3 <= 4'((Data1 / 1000) % 10);
                        in2 <= 4'((Data1 / 100) % 10);
                        in1 <= 4'((Data1 / 10) % 10);
                        in0 <= 4'(Data1 % 10);
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
                        pc <= overflow_16to8b((jump_reg == true) ? Data1 : jump_target);
                        after_jump_lock <= 2'b01;
                        clear_op <= true;
                        //TODO change next ir to nop
                        if (jal) begin
                            data_in[1] <= pc - 1; // store the next instruction address into reg
                        end
                    end
                end
                default: begin
                end
            endcase
        end
    end

    
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

    // MARK: RAM Data
    memory RAM( // 2 stages delay
        .clk(clk_main),
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
