`timescale 1ns / 1ns

module instructionLoad_tb;

    // DUT Inputs
    reg clk;
    reg rst;
    reg [31:0] r_instruction;
    reg [2:0] r_load_address;
    reg r_data_sent;
    reg [31:0] r_load_instruction;

    // DUT Outputs
    wire o_write_enable;
    wire i_write_enable;
    wire [2:0] o_address;
    wire [31:0] o_instruction;
    wire o_flush;
    wire [31:0] fetch_instruction;
    wire o_data_ready;
    wire o_flush_idex;
    reg test_flush;

    wire [31:0] o_operand1;
    wire [31:0] o_operand2;
    wire [4:0] o_ALUop;

    wire [4:0] o_addr1;
    wire [4:0] o_addr2;
    wire [31:0] i_reg_read_data1;
    wire [31:0] i_reg_read_data2;
    wire o_dec_ins_ready;
    wire o_mem_read;
    wire o_mem_write;
    wire [4:0] o_rd;
    wire o_alu_ready;
    
    // Instantiate the DUT
    instructionLoad il1 (
        .clk(clk),
        .rst(rst),
        .i_data_received(r_data_sent),
        .i_instruction(r_instruction),
        .o_write_enable(o_write_enable),
        .o_address(o_address),
        .o_instruction(o_instruction)
    );

    instructionFetch if1(
        .clk(clk),
        .rst(rst),
        .i_write_enable(o_write_enable),
        .i_load_address(o_address),
        .i_load_instruction(o_instruction),
        .i_flush(o_flush),
        .o_instruction(fetch_instruction),
        .o_data_ready(o_data_ready)
    );

    instructionDecoder id1(
        .clk(clk),
        .rst(rst),
        .i_instruction(fetch_instruction), // 32-bit i_instruction input
        .i_if_ready(o_data_ready),
        .i_flush(o_flush_idex),
        .o_flush(o_flush),
        .o_operand1(o_operand1),
        .o_operand2(o_operand2),
        .o_ALUop(o_ALUop),
        .o_addr1(o_addr1),
        .o_addr2(o_addr2),
        .o_dec_ins_ready(o_dec_ins_ready),
        .i_reg_read_data1(i_reg_read_data1),
        .i_reg_read_data2(i_reg_read_data2),
        .o_mem_read(o_mem_read),
        .o_mem_write(o_mem_write),
        .o_rd(o_rd)
    );

    wire [31:0] result;
    wire mem_read;
    wire mem_write;
    wire [4:0] rd;
    wire alu_i_flush;

    controlALU al1 (
        .clk(clk),
        .rst(rst),
        .i_operand1(o_operand1),      // First operand
        .i_operand2(o_operand2),      // Second operand
        .i_ALUOp(o_ALUop),          // Control signal to select the operation
        .i_flush(alu_i_flush),
        .o_result(result),   // Result of the operation
        .zero (),            // Zero flag for branching
        .i_dec_ins_ready(o_dec_ins_ready),
        .o_flush(o_flush_idex),
        .i_mem_read(o_mem_read),
        .i_mem_write(o_mem_write),
        .i_rd(o_rd),
        .o_mem_read(mem_read),
        .o_mem_write(mem_write),
        .o_rd(rd),
        .o_alu_ready(o_alu_ready)
    );


    wire [4:0] o_rd2;
    wire o_data_ready2;
    wire [31:0] o_write_data;
    wire o_flush2;

    dataMemory dm1(
        .clk(clk),
        .rst(rst),
        .i_result(result),
        .i_mem_read(mem_read),
        .i_mem_write(mem_write),
        .i_rd(rd),
        .i_alu_ready(o_alu_ready),
        .o_flush(alu_i_flush),
        .o_write_data(o_write_data), // to write to reg file
        .o_rd(o_rd2),
        .i_flush(o_flush2),
        .o_data_ready(o_data_ready2)
    );

    registerFile rf1 (    
        .clk(clk),
        .rst(rst),
        .i_rd(o_rd2),
        .i_reg_read_addr1(o_addr1),
        .i_reg_read_addr2(o_addr2),
        .o_reg_read_data1(i_reg_read_data1),
        .o_reg_read_data2(i_reg_read_data2),
        .i_write_data(o_write_data),
        .o_flush(o_flush2),
        .i_data_ready(o_data_ready2)
    );


    // Generate clock signal
    always begin
        #5 clk = ~clk;  // Toggle clock every 5 time units
    end

    // TEST INSTRUCTION LOAD
    initial begin
        // Initialize signals
        rst = 1'b0;  
        clk = 0;
        r_instruction = 32'b0;
        r_data_sent = 1'b0;
        
        #10;         // Hold reset high for 15ns
        rst = 1'b1;  // Deassert reset

        // Test sequence
        #10;
        r_instruction = 32'b00000000001000010000001000110011; //yes
        // r_instruction = 32'b0000_0000_0010_00001_010_00101_0000011;
        // r_instruction = 32'b0000000_00101_00010_010_01000_0100011; //S-TYPE STORE

        r_data_sent = 1'b1;

        #10;
        r_data_sent = 1'b0;

        #100;
        r_instruction = 32'b00000000001000001000001000010011; //I-TYPE
        // expecting 5
        r_data_sent = 1'b1;

        #10;
        r_data_sent = 1'b0;
        00000000000100100000001000010011
        000000111100 00100 111 001000010011



        #100;
        r_instruction = 32'b00000000100000100100001000000011; //I-TYPE LOAD
        // expecting 2
        r_data_sent = 1'b1;

        #10;
        r_data_sent = 1'b0;

        #100;
        r_instruction = 32'b0000000_00011_00011_001_00101_0010011;
        r_data_sent = 1'b1;

        #10;
        r_data_sent = 1'b0;

        #500;
        r_instruction = 32'b0000000_00011_00011_001_01010_0010011;
        r_data_sent = 1'b1;

        #10;
        r_data_sent = 1'b0;

        #100;
        r_instruction = 32'b00000000_00101_00010_010_01000_0100011; //STYPE STORE
        r_data_sent = 1'b1;

        #10;
        r_data_sent = 1'b0;

        #5000;
        $finish;  // End simulation
    end

    initial begin
        // Initialize signals

    end


endmodule