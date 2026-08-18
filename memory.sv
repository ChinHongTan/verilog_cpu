`include "top.svh"

module memory(
    input logic clk,
    input logic rst_n,
    input RAM_Address RAM_addr,
    input RAM_Data RAM_in,
    input RW RAM_write_enable,

    // signals for registers
    input RW write_enable_mem,
    output RW write_enable_wb,
    input RegAddr address_write_mem,
    output RegAddr address_write_wb,
    input RegData data_in_mem,
    output RegData data_in_wb,

    input bool load // Whether the data_in is from mem (LOAD/LOADR)
);
    RAM_Data RAM_out;
    bool load_t; // 1 clk delay for load instruction
    RegData passed_data;
    always_comb begin
        if (load_t == true) begin
            data_in_wb = RAM_out[15:0]; // immediate after RAM output
        end else begin
            data_in_wb = passed_data;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            write_enable_wb <= READ;
            address_write_wb <= 0;
        end else begin : normal_run
            address_write_wb <= address_write_mem;
            if (load == true) begin
                write_enable_wb <= WRITE;
                load_t <= true;
            end else begin : simply_pass_data
                write_enable_wb <= write_enable_mem;
                passed_data <= data_in_mem;
                load_t <= false;
            end
        end
    end
    // Data
    BRAM RAM(
        .clk,
        .pause(1'b0),
        .write(RAM_write_enable),
        .address(RAM_addr),
        .in(RAM_in),    // value to store
        .out(RAM_out)   // value to read
    );
endmodule
