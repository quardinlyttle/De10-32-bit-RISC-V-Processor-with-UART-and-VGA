//Description: this module is essentially 4 in one. The program memory, program counter, program fetch, and the if side of the
// if/id pipeline. This send side of the pipeline logic is repeated in other modules.
module instructionFetch (
    input clk,
    input rst,
    input i_write_enable,
    input [2:0] i_load_address,
    input [31:0] i_load_instruction,
    input i_flush,
    output o_data_ready,
    output [31:0] o_instruction,
    output o_debug_flag
);

// Register declaration
reg [31:0] memory [0:7];
reg [2:0] r_write_enable            = 3'b0;           
reg [2:0] r_avail_instructions      = 3'b0;  
reg [2:0] r_program_counter         = 3'b0;
reg [31:0] r_load_instruction       = 32'b0;
reg r_if_reg_occupied               = 1'b0;              
reg [31:0] r_fetch_reg              = 32'b0;             
reg [31:0] r_if_next_val            = 32'b0;           
reg r_incr_pc                       = 1'b1;
reg [1:0] r_incr_pc_delay           = 2'b0;
reg r_fetch_ready                   = 1'b0; 
reg [31:0] r_if_reg                 = 1'b0;
reg [1:0] r_fetch_ready_delay       = 2'b0;
reg r_enable_pc                     = 1'b0;
reg DEBUG_FLAG                      = 1'b0;
reg [1:0] r_if_reg_occupied_delay   = 1'b0;
reg [2:0] r_prev_prog_counter       = 3'b0;
reg r_enable_fetch                  = 1'b1;
reg r_is_fetch_enabled              = 1'b0;
reg [1:0] r_flush_delay             = 2'b0;

// PROGRAM MEMORY LOGIC //
parameter IDLE_IM = 2'b00, 
          RECEIVE = 2'b01;

reg [1:0] curr_load_state, next_load_state;

initial begin
    memory[0] = 0;
    memory[1] = 0;
    memory[2] = 0;
    memory[3] = 0;
    memory[4] = 0;
    memory[5] = 0;
    memory[6] = 0;
    memory[7] = 0;
end

// Delay logic
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_write_enable <= 2'b0;
        r_incr_pc_delay <= 2'b0;
        r_fetch_ready_delay <= 2'b0;
        r_if_reg_occupied_delay <= 2'b00;
        r_flush_delay <= 2'b0;
    end
    else begin
        r_write_enable <= {r_write_enable[0], i_write_enable};
        r_incr_pc_delay <= {r_incr_pc_delay[0], r_incr_pc};
        r_fetch_ready_delay <= {r_fetch_ready_delay[0], r_fetch_ready};
        r_if_reg_occupied_delay <= {r_if_reg_occupied_delay[0], r_if_reg_occupied};
        r_flush_delay <= {r_flush_delay[0], i_flush};
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) curr_load_state <= IDLE_IM;
    else curr_load_state <= next_load_state;
end

always @(*) begin
    next_load_state = curr_load_state;
    case (curr_load_state)
        IDLE_IM: begin
            if (r_write_enable == 2'b01) next_load_state = RECEIVE;
            else next_load_state = IDLE_IM;
        end
        RECEIVE: begin
            next_load_state = IDLE_IM;
        end
    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_avail_instructions <= 3'b0;
        r_load_instruction <= 32'b0;
    end
    else begin
        case (curr_load_state)
            IDLE_IM: begin
            end

            RECEIVE: begin
                r_avail_instructions <= r_avail_instructions + 1'b1; 
                memory[i_load_address] <= i_load_instruction; 
            end
        endcase
    end
end

// PROGRAM COUNTER LOGIC //
parameter IDLE_PC = 2'b00, 
          INCR = 2'b01;

reg [1:0] curr_pc_state, next_pc_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_pc_state <= IDLE_PC;
    else curr_pc_state <= next_pc_state;
end

always @(*) begin
    next_pc_state = curr_pc_state;
    case (curr_pc_state)
        IDLE_PC: begin
            if (r_incr_pc_delay == 2'b01 && r_program_counter < r_avail_instructions) next_pc_state = INCR; 
        end
        INCR: begin
            next_pc_state = IDLE_PC;
        end
    endcase
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_program_counter <= 3'b0;
        r_enable_pc <= 1'b1;
        DEBUG_FLAG <= 0;
    end else begin
        case (curr_pc_state)
            IDLE_PC: begin
                r_enable_pc <= 1'b1;
            end
            INCR: begin
                if (r_enable_pc == 1'b1) begin
                    r_program_counter <= r_program_counter + 1'b1;
                    r_enable_pc <= 1'b0;
                    DEBUG_FLAG <= ~DEBUG_FLAG;
                end
            end
        endcase
    end
end

// INSTRUCTION FETCH LOGIC //
parameter IDLE_IF = 2'b00, 
          FETCH = 2'b01,
          PASS = 2'b10;

reg [1:0] curr_fetch_state, next_fetch_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_fetch_state <= IDLE_IF;
    else curr_fetch_state <= next_fetch_state;
end

reg r_if_reg_occupied_pulse;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_if_reg_occupied_pulse <= 1'b0;
    end else begin
        r_if_reg_occupied_pulse <= r_fetch_ready && !r_if_reg_occupied;
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_enable_fetch <= 1'b1;
    end else begin
        if (i_flush || (curr_fetch_state == FETCH)) begin
            r_enable_fetch <= 1'b0;
        end 

        else if (curr_fetch_state == PASS) begin
            r_enable_fetch <= 1'b1;
        end
    end
end

// PROGRAM COUNTER LOGIC
// compare the program counter to the #of available instructions which will dictate whether or not it will fetch
// if equal no fetch if less than, fetch
always @(*) begin
    next_fetch_state = curr_fetch_state;
    case (curr_fetch_state)
        IDLE_IF: begin
            if (r_enable_fetch == 1'b1 && r_program_counter < 8 && r_program_counter < r_avail_instructions) begin
                next_fetch_state = FETCH;
            end
        end

        FETCH: begin
            if (r_if_reg_occupied_pulse) 
                next_fetch_state = PASS;
            else
                next_fetch_state = FETCH;
        end
        PASS: begin
            next_fetch_state = IDLE_IF;
        end
        default: begin
            next_fetch_state = IDLE_IF;
        end
    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_fetch_reg <= 32'b0;
        r_if_next_val <= 32'b0;
        r_fetch_ready <= 1'b0;
    end
    else begin
    case (curr_fetch_state)
        IDLE_IF: begin
            r_fetch_reg <= 32'b0;
            r_incr_pc <= 1'b0;
            r_fetch_ready <= 1'b0;
        end

        FETCH: begin
            r_fetch_reg <= memory[r_program_counter];
            r_fetch_ready <= 1'b1;
        end

        PASS: begin
            r_if_next_val <= r_fetch_reg;
            r_incr_pc <= 1'b1;
        end
    endcase
    end
end

// IF/ID LOGIC //
parameter IDLE_IF_ID = 2'b00, 
          STORE = 2'b01;

reg [1:0] curr_if_state, next_if_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_if_state <= IDLE_IF;
    else curr_if_state <= next_if_state;
end

always @(*) begin
    next_if_state = curr_if_state;
    case (curr_if_state)
        IDLE_IF_ID: begin
            if (r_fetch_ready == 1'b1) next_if_state = STORE; 
        end

        STORE: begin
            if (i_flush == 1'b1) next_if_state = IDLE_IF_ID; 
        end
    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_if_reg_occupied <= 1'b0;
        r_if_reg <= 32'b0;
    end else begin
        case (curr_if_state)
            IDLE_IF_ID: begin
                r_if_reg_occupied <= 1'b0;
            end
            STORE: begin 
                r_if_reg_occupied <= 1'b1; 
                r_if_reg <= r_if_next_val;
            end
        endcase
    end
end

// IO Assignments
assign o_data_ready = r_if_reg_occupied;
assign o_instruction = r_if_reg;
assign o_debug_flag = DEBUG_FLAG;
endmodule