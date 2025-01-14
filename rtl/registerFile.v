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
    output [4:0] o_debug_flag
);

reg [31:0] reg_array [0:16];
reg [2:0] r_data_ready_delay = 0;
reg r_flush_sig = 0;

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
assign o_debug_flag = {reg_array[4][4:0]};
endmodule