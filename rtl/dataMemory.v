module dataMemory (
    input clk,
    input rst,
    input [31:0] i_result,
    input i_mem_read,
    input i_mem_write,
    input [4:0] i_rd,
    input i_alu_ready,
    output o_flush,
    output [31:0] o_write_data, // to write to reg file
    output [4:0] o_rd,
    input i_flush,
    output o_data_ready,
    output [4:0] o_debug_flag
);

reg [31:0] memory_array [0:16];
reg [1:0] r_alu_ready_delay = 0;
reg r_mem_read = 0;
reg r_mem_write = 0;
reg [4:0] r_rd = 0;
reg [31:0] r_result = 0;
reg r_flush_sig = 0;
reg r_begin_mem = 0;
reg [1:0] r_begin_mem_delay = 0;
wire r_mem_fin;
reg [1:0] r_mem_fin_delay = 0;
reg [4:0] r_addr = 0; //WILL BE PART OF THE RESULT
reg [1:0] r_mem_op = 0;
reg r_wb_reg_occupied = 0;
wire r_data_ready;
reg [31:0] r_data_write = 0;
reg [31:0] r_wb_data_write = 0;
reg [4:0] r_wb_rd = 0;
reg r_wb_reg_occupied_pulse = 0;
reg [4:0] DEBUG_FLAG = 0;
initial begin
    memory_array[0] = 32'b001;
    memory_array[1] = 32'b001;
    memory_array[2] = 32'b001;
    memory_array[3] = 32'b001;
    memory_array[4] = 32'b001;
    memory_array[5] = 32'b001;
    memory_array[6] = 32'b001;
    memory_array[7] = 32'b001;
    memory_array[8] = 32'b001;
    memory_array[9] = 32'b001;
    memory_array[10] = 32'b001;
    memory_array[11] = 32'b001;
    memory_array[12] = 32'b001;
    memory_array[13] = 32'b001;
    memory_array[14] = 32'b001;
    memory_array[15] = 32'b001;
    memory_array[16] = 32'b001;
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_wb_reg_occupied_pulse <= 1'b0;
    end else begin
        r_wb_reg_occupied_pulse <= r_data_ready && !r_wb_reg_occupied;
    end
end

parameter IDLE_EXMEM = 2'b00, 
          STORE = 2'b01,
          FLUSH = 2'b10;

reg [1:0] curr_exmem_state, next_exmem_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_exmem_state <= IDLE_EXMEM;
    else curr_exmem_state <= next_exmem_state;
end
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_alu_ready_delay <= 2'b0;
        r_begin_mem_delay <= 2'b0;
        r_mem_fin_delay <= 2'b0;
    end
    else begin
        r_alu_ready_delay <= {r_alu_ready_delay[0], i_alu_ready};
        r_begin_mem_delay <= {r_begin_mem_delay[0], r_begin_mem};
        r_mem_fin_delay <= {r_mem_fin_delay[0], r_mem_fin};
    end
end

always @(*) begin
    next_exmem_state = curr_exmem_state;
    case (curr_exmem_state)
        IDLE_EXMEM: begin
            if (r_alu_ready_delay == 2'b01) next_exmem_state = STORE;
        end

        STORE: begin
            // if (r_decode_fin_delay == 2'b01) next_mem_state = FLUSH;
            if (r_mem_fin_delay == 2'b01) next_exmem_state = FLUSH;
        end

        FLUSH: begin
            next_exmem_state = IDLE_EXMEM;
        end
    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_flush_sig <= 1'b0; // Signal a flush
        r_begin_mem <= 1'b0;
        r_mem_read <= 0;
        r_mem_write <= 0;
        r_rd <= 0;
        r_result <= 0;
        r_addr <= 0;
        r_mem_op <= 2'b0;
    end else begin
        case (curr_exmem_state)
            IDLE_EXMEM: begin
                //input_reg <= input_reg;
                r_flush_sig <= 1'b0; // clear flush signal

                r_mem_read <= r_mem_read;
                r_mem_write <= r_mem_write;
                r_rd <= r_rd;
                r_result <= r_result;
                r_addr <= r_addr;
                r_mem_op <= r_mem_op;
            end

            STORE: begin
                // r_id_reg <= i_instruction; // Latch the instruction
                r_begin_mem <= 1'b1;
                r_mem_read <= i_mem_read;
                r_mem_write <= i_mem_write;
                r_rd <= i_rd;
                r_result <= i_result;
                r_addr <= i_result[4:0];
                r_mem_op <= {i_mem_write, i_mem_read};
            end

            FLUSH: begin
                r_flush_sig <= 1'b1; // Signal a flush
                r_begin_mem <= 1'b0;

                r_mem_read <= r_mem_read;
                r_mem_write <= r_mem_write;
                r_rd <= r_rd;
                r_result <= r_result; //RESULT IS THE WRITE DATA OR THE DATA ADDRESS
                r_mem_op <= r_mem_op;
            end
        endcase
    end
end

// MEM LOGIC //

parameter IDLE_MEM = 3'b000, 
          HOLD = 3'b001,
          READ = 3'b010,
          WRITE = 3'b011,
          PASS = 3'b100; //WILL FLUSH ONLY ONCE DECODED RESULT IS PASSED

reg [2:0] curr_mem_state, next_mem_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_mem_state <= IDLE_MEM;
    else curr_mem_state <= next_mem_state;
end

always @(*) begin
    next_mem_state = curr_mem_state;
    case (curr_mem_state)
        IDLE_MEM: begin
            if (r_begin_mem_delay == 2'b01) begin
                if (r_mem_op == 2'b01) next_mem_state = READ;
                else if (r_mem_op == 2'b10) next_mem_state = WRITE;
                else next_mem_state = HOLD;
            end
        end

        HOLD: begin
            if (r_wb_reg_occupied_pulse) next_mem_state = PASS;
        end

        WRITE: begin
            //clk cycle THIS ONE WILL RAISE MEM DONE AS WELL
            next_mem_state = IDLE_MEM;
        end

        READ: begin
            if (r_wb_reg_occupied_pulse) next_mem_state = PASS;
        end

        PASS: begin
            // clk cycle RAISE MEM DONE
            next_mem_state = IDLE_MEM;
        end

    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_data_write <= 0;
        r_wb_rd <= 0;
        r_wb_data_write <= 0;
    end else begin
        case (curr_mem_state)
            IDLE_MEM: begin

            end

            HOLD: begin
                r_data_write <= r_result;
            end

            WRITE: begin
                memory_array[r_rd] <= r_result;
            end

            READ: begin
                r_data_write <= memory_array[r_result];
            end

            PASS: begin
                r_wb_rd <= r_rd;
                r_wb_data_write <= r_data_write;
            end
        endcase
    end
end

// MEM/WB  //
parameter IDLE_WB = 2'b00, 
          STORE_WB = 2'b01;

reg [1:0] curr_wb_state, next_wb_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_wb_state <= IDLE_WB;
    else curr_wb_state <= next_wb_state;
end

always @(*) begin
    next_wb_state = curr_wb_state;
    case (curr_wb_state)
        IDLE_WB: begin
            if (r_data_ready == 1'b1) next_wb_state = STORE_WB; //limit to 8 later
        end

        STORE_WB: begin
            if (i_flush == 1'b1) next_wb_state = IDLE_WB; //if ID in decoder module raises high signal
        end
    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_wb_reg_occupied <= 1'b0;
    end else begin
        case (curr_wb_state)
            IDLE_WB: begin
                r_wb_reg_occupied <= 1'b0;
            end
            STORE_WB: begin //make flush a handshake signal
                r_wb_reg_occupied <= 1'b1; // signal to the decoder that data is ready
            end
        endcase
    end
end

assign o_flush = r_flush_sig;
assign o_write_data = r_wb_data_write;
assign o_rd = r_wb_rd;
assign o_data_ready = r_wb_reg_occupied;
assign r_mem_fin = (curr_mem_state == PASS);
assign r_data_ready = (curr_mem_state == HOLD) || (curr_mem_state == READ);
assign o_debug_flag = r_wb_rd;
endmodule