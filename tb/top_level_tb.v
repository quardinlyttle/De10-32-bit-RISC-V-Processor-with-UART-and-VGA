module top_level_tb;

    reg clk;
    reg rst;
    wire il1_if1_write_enable;
    wire [2:0] il1_if1_load_address;
    wire [31:0] il1_if1_load_instruction;
    wire id1_if1_flush;

    wire [31:0] if1_id1_instruction;
    wire if1_id1_data_ready;
    wire [31:0] id1_al1_operand1;
    wire [31:0] id1_al1_operand2;
    wire [4:0] id1_al1_aluop;
    wire al1_id1_flush;
    wire [4:0] id1_rf1_addr1;
    wire [4:0] id1_rf1_addr2;
    wire id1_al1_dec_ins_ready;
    wire [31:0] rf1_id1_reg_read_data1;
    wire [31:0] rf1_id1_reg_read_data2;
    wire id1_al1_mem_read;
    wire id1_al1_mem_write;
    wire [4:0] id1_al1_rd;
    wire [31:0] al1_dm1_result;
    wire [4:0] al1_dm1_rd;
    wire al1_dm1_alu_ready;

    wire al1_dm1_mem_read;
    wire al1_dm1_mem_write;
    wire rf1_dm1_flush;

    wire dm1_rf1_data_ready;
    wire [4:0] dm1_rf1_rd;
    wire [31:0] dm1_rf1_write_data;
    wire dm1_al1_flush;

    reg [31:0] r_instruction;
    reg r_data_sent;
    instructionLoad il(
        .clk(clk),
        .rst(rst),
        .i_data_received(r_data_sent),
        .i_instruction(r_instruction),
        .o_write_enable(il1_if1_write_enable),
        .o_address(il1_if1_load_address),
        .o_instruction(il1_if1_load_instruction),
        .o_debug_flag()
    );


    instructionFetch if1(
        .clk(clk),
        .rst(rst),
        .i_write_enable(il1_if1_write_enable),
        .i_load_address(il1_if1_load_address),
        .i_load_instruction(il1_if1_load_instruction),
        .i_flush(id1_if1_flush),
        .o_instruction(if1_id1_instruction),
        .o_data_ready(if1_id1_data_ready),
        .o_debug_flag()
    );
    instructionDecoder id1(
        .clk(clk),
        .rst(rst),
        .i_instruction(if1_id1_instruction), // 32-bit i_instruction input
        .i_if_ready(if1_id1_data_ready),
        .i_flush(al1_id1_flush),
        .o_flush(id1_if1_flush),
        .o_operand1(id1_al1_operand1),
        .o_operand2(id1_al1_operand2),
        .o_ALUop(id1_al1_aluop),
        .o_addr1(id1_rf1_addr1),
        .o_addr2(id1_rf1_addr2),
        .o_dec_ins_ready(id1_al1_dec_ins_ready),
        .i_reg_read_data1(rf1_id1_reg_read_data1),
        .i_reg_read_data2(rf1_id1_reg_read_data2),
        .o_mem_read(id1_al1_mem_read),
        .o_mem_write(id1_al1_mem_write),
        .o_rd(id1_al1_rd),
        .o_debug_flag()
    );
    controlALU al1 (
        .clk(clk),
        .rst(rst),
        .i_operand1(id1_al1_operand1),      // First operand
        .i_operand2(id1_al1_operand2),      // Second operand
        .i_ALUOp(id1_al1_aluop),          // Control signal to select the operation
        .i_flush(dm1_al1_flush),
        .o_result(al1_dm1_result),   // Result of the operation
        .zero (),            // Zero flag for branching
        .i_dec_ins_ready(id1_al1_dec_ins_ready),
        .o_flush(al1_id1_flush),
        .i_mem_read(id1_al1_mem_read),
        .i_mem_write(id1_al1_mem_write),
        .i_rd(id1_al1_rd),
        .o_mem_read(al1_dm1_mem_read),
        .o_mem_write(al1_dm1_mem_write),
        .o_rd(al1_dm1_rd),
        .o_alu_ready(al1_dm1_alu_ready),
        .o_debug_flag()
    );
    dataMemory dm1(
        .clk(clk),
        .rst(rst),
        .i_result(al1_dm1_result),
        .i_mem_read(al1_dm1_mem_read),
        .i_mem_write(al1_dm1_mem_write),
        .i_rd(al1_dm1_rd),
        .i_alu_ready(al1_dm1_alu_ready),
        .o_flush(dm1_al1_flush),
        .o_write_data(dm1_rf1_write_data), // to write to reg file
        .o_rd(dm1_rf1_rd),
        .i_flush(rf1_dm1_flush),
        .o_data_ready(dm1_rf1_data_ready),
        .o_debug_flag()
    );
    registerFile rf1 (    
        .clk(clk),
        .rst(rst),
        .i_rd(dm1_rf1_rd),
        .i_reg_read_addr1(id1_rf1_addr1),
        .i_reg_read_addr2(id1_rf1_addr2),
        .o_reg_read_data1(rf1_id1_reg_read_data1),
        .o_reg_read_data2(rf1_id1_reg_read_data2),
        .i_write_data(dm1_rf1_write_data),
        .o_flush(rf1_dm1_flush),
        .i_data_ready(dm1_rf1_data_ready),
        .o_debug_flag()
    );

    always begin
        #5 clk = ~clk;  // Toggle clock every 5 time units
    end

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
        r_instruction = 32'b0000000_00010_00010_000_00100_0110011; //yes
        // r_instruction = 32'b0000_0000_0010_00001_010_00101_0000011;
        // r_instruction = 32'b0000000_00101_00010_010_01000_0100011; //S-TYPE STORE

        r_data_sent = 1'b1;

        #10;
        r_data_sent = 1'b0;

        #100;
        r_instruction = 32'b000000000010_00001_000_00101_0010011; //I-TYPE
        // expecting 5
        r_data_sent = 1'b1;

        #10;
        r_data_sent = 1'b0;


        #100;
        r_instruction = 32'b0000000_01000_00100_100_00100_0000011; //I-TYPE LOAD
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
    //=====
endmodule