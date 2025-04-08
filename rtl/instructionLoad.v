// Description: this module takes in instructions from UART once UART has signaled that there is an instruction ready
// to be loaded into the program memory. It's done this way as the instructions are given through user input meaning
// that there are times when the value of instruction bits are all 0. It is important that it is confirmed that there
// is a valid instruction before loading.

module instructionLoad ( 
    input clk,
    input rst,
    input i_data_received,
    input [31:0] i_instruction,
    output o_write_enable,
    output [2:0] o_address,
    output [31:0] o_instruction,
	output o_debug_flag
);

reg [31:0] r_instruction    = 32'b0;
reg r_write_enable          = 1'b0;
reg [1:0] r_data_received   = 2'b0;
reg [2:0] r_address         = 3'b000;
reg r_debug_flag            = 1'b0;

// State declaration
parameter IDLE = 2'b00, 
          RECEIVE = 2'b01, 
          WRITE = 2'b10, 
          ADDR_INCR = 2'b11;
reg [1:0] curr_state, next_state;

// Edge detection logic 
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_data_received <= 2'b0;
    end
    else begin
        r_data_received <= {r_data_received[0], i_data_received};
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) curr_state <= IDLE;
    else curr_state <= next_state;
end

// State transition logic
always @(*) begin
    next_state = curr_state;
    case (curr_state)
        IDLE: begin
            if (r_data_received == 2'b01 && r_address <= 3'b111) next_state = RECEIVE;
            else next_state = IDLE;
        end
        RECEIVE: begin
            next_state = WRITE;
        end
        WRITE: begin
            next_state = ADDR_INCR;
        end
        ADDR_INCR: begin
            next_state = IDLE;
        end
    endcase
end

// State events
always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_instruction <= 32'b0;
        r_write_enable <= 1'b0;
        r_address <= 3'b0;
    end
    else begin
        case (curr_state)
            IDLE: begin
                r_instruction <= 32'b0;
                r_write_enable <= 1'b0;

                if (r_data_received == 2'b01) r_write_enable <= 1'b1;
            end

            RECEIVE: begin
                r_instruction <= i_instruction;
					 r_debug_flag <= ~r_debug_flag;
            end

            WRITE: begin
            end

            ADDR_INCR: begin
                r_address <= r_address + 1'b1;
            end
        endcase
    end
end

// IO Assignments
assign o_instruction = r_instruction;
assign o_write_enable = r_write_enable;
assign o_address = r_address;
assign o_debug_flag = r_debug_flag;
endmodule