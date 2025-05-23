module registerFile (
    input clk,
    input rst,
    input [4:0] i_rd,
    input i_data_ready, //write enable eq
    input [31:0] i_write_data,
    input [4:0] i_reg_read_addr1,
    input [4:0] i_reg_read_addr2,
    output [31:0] o_reg_read_data1,
    output [31:0] o_reg_read_data2,
    output o_flush,
    output [31:0] o_reg_array1,
    output [31:0] o_reg_array2,
    output [31:0] o_reg_array0,
    output [31:0] o_reg_array3,
    output [31:0] o_reg_array4, 
    output [31:0] o_reg_array5, 
    output [31:0] o_reg_array6, 
    output [31:0] o_reg_array7, 
    output [31:0] o_reg_array8, 
    output [31:0] o_reg_array9, 
    output [31:0] o_reg_array10,
    output [31:0] o_reg_array11, 
    output [31:0] o_reg_array12,
    output [31:0] o_reg_array13,
    output [31:0] o_reg_array14,
    output [31:0] o_reg_array15,
    output [31:0] o_reg_array16,
    output [31:0] o_reg_array17,
    output [31:0] o_reg_array18,
    output [31:0] o_reg_array19, 
    output [31:0] o_reg_array20,
    output [31:0] o_reg_array21,
    output [31:0] o_reg_array22,
    output [31:0] o_reg_array23,
    output [31:0] o_reg_array24,
    output [31:0] o_reg_array25,
    output [31:0] o_reg_array26,
    output [31:0] o_reg_array27,
    output [31:0] o_reg_array28,
    output [31:0] o_reg_array29,
    output [31:0] o_reg_array30,
    output [31:0] o_reg_array31
);

assign o_reg_array0 = reg_array[0];
assign o_reg_array1 = reg_array[1];
assign o_reg_array2 = reg_array[2];
assign o_reg_array3 = reg_array[3];
assign o_reg_array4 = reg_array[4];
assign o_reg_array5 = reg_array[5];
assign o_reg_array6 = reg_array[6];
assign o_reg_array7 = reg_array[7];
assign o_reg_array8 = reg_array[8]; 
assign o_reg_array9 = reg_array[9]; 
assign o_reg_array10 = reg_array[10];
assign o_reg_array11 = reg_array[11]; 
assign o_reg_array12 = reg_array[12];
assign o_reg_array13 = reg_array[13];
assign o_reg_array14 = reg_array[14];
assign o_reg_array15 = reg_array[15];
assign o_reg_array16 = reg_array[16];
assign o_reg_array17 = reg_array[17];
assign o_reg_array18 = reg_array[18];
assign o_reg_array19 = reg_array[19];
assign o_reg_array20 = reg_array[20];
assign o_reg_array21 = reg_array[21];
assign o_reg_array22 = reg_array[22];
assign o_reg_array23 = reg_array[23];
assign o_reg_array24 = reg_array[24];
assign o_reg_array25 = reg_array[25];
assign o_reg_array26 = reg_array[26];
assign o_reg_array27 = reg_array[27];
assign o_reg_array28 = reg_array[28];
assign o_reg_array29 = reg_array[29];
assign o_reg_array30 = reg_array[30];
assign o_reg_array31 = reg_array[31];

reg [31:0] reg_array [0:31];
reg [2:0] r_data_ready_delay;
reg r_flush_sig;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_data_ready_delay <= 2'b0;
    end
    else begin
        r_data_ready_delay <= {r_data_ready_delay[0], i_data_ready};
    end
end

//testing
initial begin
    reg_array[0] = 32'd0;
    reg_array[1] = 32'd2;
    reg_array[2] = 32'd3;
    reg_array[3] = 32'd10;
    reg_array[4] = 32'd0;
    reg_array[5] = 32'd5;
    reg_array[6] = 32'd0;
    reg_array[7] = 32'd0;
    reg_array[8] = 32'd0;
    reg_array[9] = 32'd0;
    reg_array[10] = 32'd0;
    reg_array[11] = 32'd15;
    reg_array[12] = 32'd0;
    reg_array[13] = 32'd0;
    reg_array[14] = 32'd0;
    reg_array[15] = 32'd0;
    reg_array[16] = 32'd0;
    reg_array[17] = 32'd0;
    reg_array[18] = 32'd0;
    reg_array[19] = 32'd15;
    reg_array[20] = 32'd0;
    reg_array[21] = 32'd0;
    reg_array[22] = 32'd0;
    reg_array[23] = 32'd0;
    reg_array[24] = 32'd0;
    reg_array[25] = 32'd0;
    reg_array[26] = 32'd0;
    reg_array[27] = 32'd0;
    reg_array[28] = 32'd0;
    reg_array[29] = 32'd0;
    reg_array[30] = 32'd0;
    reg_array[31] = 32'd0;
end


parameter IDLE = 2'b00,
          BUFFER = 2'b01,
          WRITE = 2'b10,
          FLUSH = 2'b11;

reg [1:0] curr_state, next_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_state <= IDLE;
    else curr_state <= next_state;
end

always @(*) begin
    next_state = curr_state;
    case (curr_state)
        IDLE: begin
            if (r_data_ready_delay == 2'b01) next_state = BUFFER;
        end

        BUFFER: begin
            next_state = WRITE;
        end
        WRITE: begin
            next_state = FLUSH;
        end

        FLUSH: begin
            next_state = IDLE;
        end
    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_flush_sig <= 1'b0;
    end else begin
        case (curr_state)
            IDLE: begin
                //input_reg <= input_reg;
                r_flush_sig <= 1'b0; // Clear flush signal
            end

            WRITE: begin
                // r_id_reg <= i_instruction; // Latch the instruction
                reg_array[i_rd] <= i_write_data;
            end

            FLUSH: begin
                r_flush_sig <= 1'b1; // Signal a flush
                // r_ex_ready <= 1'b0;

            end
        endcase
    end
end


assign o_reg_read_data1 = reg_array[i_reg_read_addr1];
assign o_reg_read_data2 = reg_array[i_reg_read_addr2];
assign o_flush = r_flush_sig;
endmodule