module controlALU (
    input clk,
    input rst,
    input i_flush,
    input i_mem_read,
    input i_mem_write,
    input [4:0] i_rd,
    input [31:0] i_operand1,      // First operand
    input [31:0] i_operand2,      // Second operand
    input [4:0] i_ALUOp,          // Control signal to select the operation
    input i_dec_ins_ready,
    output [31:0] o_result,   // Result of the operation
    output zero,             // Zero flag for branching
    output o_flush,
    output o_mem_read,
    output o_mem_write,
    output [4:0] o_rd,
    output o_alu_ready,
    output [4:0]o_debug_flag
);

reg [1:0] r_id_ready_delay = 0; //when id side of idex is ready
reg r_ex_ready = 0;
reg r_begin_alu = 0;
reg [1:0]r_begin_alu_delay = 0;
reg [1:0] r_ex_ready_delay = 0; // once stored begin the ALU operations
wire r_alu_fin;
reg [1:0] r_alu_fin_delay = 0;
reg r_flush_sig = 0;
reg [31:0] r_operand1 = 0;      // First operand
reg [31:0] r_operand2 = 0;      // Second operand
reg [4:0] r_ALUOp = 0;          // Control signal to select the operation
reg r_mem_read = 0;
reg r_mem_write = 0;
reg [4:0] r_rd = 0;
reg [31:0] r_result = 0;
reg r_exmem_reg_occupied = 0;
reg r_exmem_mem_read = 0;
reg r_exmem_mem_write = 0;
reg [4:0] r_exmem_rd = 0;
reg [4:0] DEBUG_FLAG = 0;
reg [31:0] r_exmem_result = 0;
wire r_result_ready;
// ALU operation codes (encoded control signals)
parameter ALU_ADD   = 5'b0000;  // Addition
parameter ALU_SUB   = 5'b0001;  // Subtraction
parameter ALU_AND   = 5'b0010;  // Logical AND
parameter ALU_OR    = 5'b0011;  // Logical OR
parameter ALU_XOR   = 5'b0100;  // Logical XOR
parameter ALU_SLL   = 5'b0101;  // Logical left shift
parameter ALU_SRL   = 5'b0110;  // Logical right shift
parameter ALU_SRA   = 5'b0111;  // Arithmetic right shift
parameter ALU_SLT   = 5'b1000;  // Set less than
parameter ALU_SLTU  = 5'b1001;  // Set less than unsigned
parameter ALU_ADDI  = 5'b1010;  // Addition immediate
parameter ALU_XORI  = 5'b1011;  // XOR immediate
parameter ALU_ORI   = 5'b1100;  // OR immediate
parameter ALU_ANDI  = 5'b1101;  // AND immediate
parameter ALU_SLLI  = 5'b1110;  // Logical left shift immediate
parameter ALU_SRLI  = 5'b1111;  // Logical right shift immediate
parameter ALU_SRAI  = 5'b10000; // Arithmetic right shift immediate
parameter ALU_SLTI  = 5'b10001; // Set less than immediate
parameter ALU_SLTIU = 5'b10010; // Set less than unsigned immediate
parameter ALU_SW = 5'b10100; // Set less than unsigned immediate

reg r_exmem_reg_occupied_pulse;
// FOR ANY DELAYS
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_id_ready_delay <= 2'b0;
        r_begin_alu_delay <= 2'b0;
    end
    else begin
        r_id_ready_delay <= {r_id_ready_delay[0], i_dec_ins_ready};
        r_begin_alu_delay <={r_begin_alu_delay[0], r_begin_alu};
        r_alu_fin_delay <= {r_alu_fin_delay[0], r_alu_fin};
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_exmem_reg_occupied_pulse <= 1'b0;
    end else begin
        r_exmem_reg_occupied_pulse <= r_result_ready && !r_exmem_reg_occupied;
    end
end

parameter IDLE_EX = 2'b00, 
          STORE = 2'b01,
          FLUSH = 2'b10;

reg [1:0] curr_ex_state, next_ex_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_ex_state <= IDLE_EX;
    else curr_ex_state <= next_ex_state;
end

always @(*) begin
    next_ex_state = curr_ex_state;
    case (curr_ex_state)
        IDLE_EX: begin
            if (r_id_ready_delay == 2'b01) next_ex_state = STORE;
        end

        STORE: begin
            if (r_alu_fin_delay == 2'b01) next_ex_state = FLUSH;
        end

        FLUSH: begin
            next_ex_state = IDLE_EX;
        end
    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_operand1 <= 0;
        r_operand2 <= 0;
        r_ALUOp <= 0;
        r_begin_alu <= 0;
    end else begin
        case (curr_ex_state)
            IDLE_EX: begin
                //input_reg <= input_reg;
                r_flush_sig <= 1'b0; // Clear flush signal
                r_operand1 <= r_operand1;
                r_operand2 <= r_operand2;
                r_ALUOp <= r_ALUOp;
                r_mem_read <= r_mem_read;
                r_mem_write <= r_mem_write;
                r_rd <= r_rd;
            end

            STORE: begin
                // r_id_reg <= i_instruction; // Latch the instruction
                r_begin_alu <= 1'b1;
                r_operand1 <= i_operand1;
                r_operand2 <= i_operand2;
                r_ALUOp <= i_ALUOp;
                r_mem_read <= i_mem_read;
                r_mem_write <= i_mem_write;
                r_rd <= i_rd;
            end

            FLUSH: begin
                r_flush_sig <= 1'b1; // Signal a flush
                // r_ex_ready <= 1'b0;
                r_begin_alu <= 1'b0;
                r_operand1 <= r_operand1;
                r_operand2 <= r_operand2;
                r_ALUOp <= r_ALUOp;
                r_mem_read <= r_mem_read;
                r_mem_write <= r_mem_write;
                r_rd <= r_rd;
            end
        endcase
    end
end

// ALU LOGIC //

parameter IDLE_ALU = 2'b00, 
          ALU = 2'b01,
          PASS = 2'b10; //WILL FLUSH ONLY ONCE DECODED RESULT IS PASSED

reg [1:0] curr_alu_state, next_alu_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_alu_state <= IDLE_ALU;
    else curr_alu_state <= next_alu_state;
end

always @(*) begin
    next_alu_state = curr_alu_state;
    case (curr_alu_state)
        IDLE_ALU: begin
            if (r_begin_alu_delay == 2'b01) next_alu_state = ALU;
        end

        ALU: begin
            // if (r_exmem_reg_occupied_pulse) 
            //     next_dec_state = PASS;
            // else

            if (r_exmem_reg_occupied_pulse) next_alu_state = PASS; 
            else next_alu_state = ALU;
        end

        PASS: begin
            next_alu_state = IDLE_ALU;
        end

    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_exmem_result <= 32'b0;
        r_exmem_rd <= 5'b0;
        r_exmem_mem_read <= 1'b0;
        r_exmem_mem_write <= 1'b0;
    end else begin
        case (curr_alu_state)
            IDLE_ALU: begin

            end
            
            ALU: begin
                case (r_ALUOp)
                ALU_ADD:   r_result <= r_operand1 + r_operand2;              // Addition
                ALU_SUB:   r_result <= r_operand1 - r_operand2;              // Subtraction
                ALU_AND:   r_result <= r_operand1 & r_operand2;              // Logical AND
                ALU_OR:    r_result <= r_operand1 | r_operand2;              // Logical OR
                ALU_XOR:   r_result <= r_operand1 ^ r_operand2;              // Logical XOR
                ALU_SLL:   r_result <= r_operand1 << r_operand2[4:0];        // Logical left shift
                ALU_SRL:   r_result <= r_operand1 >> r_operand2[4:0];        // Logical right shift
                ALU_SRA:   r_result <= $signed(r_operand1) >>> r_operand2[4:0]; // Arithmetic right shift
                ALU_SLT:   r_result <= ($signed(r_operand1) < $signed(r_operand2)) ? 32'b1 : 32'b0; // Set less than
                ALU_SLTU:  r_result <= (r_operand1 < r_operand2) ? 32'b1 : 32'b0; // Set less than unsigned
                
                // I-type operations (operand2 is treated as an immediate)
                ALU_ADDI:  r_result <= r_operand1 + r_operand2;              // Addition with immediate
                ALU_XORI:  r_result <= r_operand1 ^ r_operand2;              // XOR with immediate
                ALU_ORI:   r_result <= r_operand1 | r_operand2;              // OR with immediate
                ALU_ANDI:  r_result <= r_operand1 & r_operand2;              // AND with immediate
                ALU_SLLI:  r_result <= r_operand1 << r_operand2[4:0];        // Logical left shift immediate
                ALU_SRLI:  r_result <= r_operand1 >> r_operand2[4:0];        // Logical right shift immediate
                ALU_SRAI:  r_result <= $signed(r_operand1) >>> r_operand2[4:0]; // Arithmetic right shift immediate
                ALU_SLTI:  r_result <= ($signed(r_operand1) < $signed(r_operand2)) ? 32'b1 : 32'b0; // Set less than immediate
                ALU_SLTIU: r_result <= (r_operand1 < r_operand2) ? 32'b1 : 32'b0; // Set less than unsigned immediate
                ALU_SW: r_result <= r_operand2; // Set less than unsigned immediate
                endcase

            end

            PASS: begin
                //pass the values to ID/EX pipeline by holding these values until
                r_exmem_result <= r_result;
                r_exmem_mem_read <= r_mem_read;
                r_exmem_mem_write <= r_mem_write;
                r_exmem_rd <= r_rd;
            end
        endcase
    end
end

// EX/MEM LOGIC //

parameter IDLE_EXMEM = 2'b00, 
          STORE_EXMEM = 2'b01;

reg [1:0] curr_exmem_state, next_exmem_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_exmem_state <= IDLE_EXMEM;
    else curr_exmem_state <= next_exmem_state;
end

always @(*) begin
    next_exmem_state = curr_exmem_state;
    case (curr_exmem_state)
        IDLE_EXMEM: begin
            if (r_result_ready == 1'b1) next_exmem_state = STORE_EXMEM; //limit to 8 later
        end

        STORE_EXMEM: begin
            if (i_flush == 1'b1) next_exmem_state = IDLE_EXMEM; //if ID in decoder module raises high signal
            // hold onto r_if_reg value til then
            // flush coming all the way from controlUnit
        end
    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_exmem_reg_occupied <= 1'b0;
    end else begin
        case (curr_exmem_state)
            IDLE_EXMEM: begin
                r_exmem_reg_occupied <= 1'b0;
            end
            STORE_EXMEM: begin //make flush a handshake signal
                r_exmem_reg_occupied <= 1'b1; // signal to the decoder that data is ready
            end
        endcase
    end
end
assign o_flush = r_flush_sig;
assign o_result = r_exmem_result;
assign o_mem_read = r_exmem_mem_read;
assign o_mem_write = r_exmem_mem_write;
assign o_rd = r_exmem_rd;
assign o_alu_ready = r_exmem_reg_occupied;
assign r_alu_fin = (curr_alu_state == PASS);
assign r_result_ready = (curr_alu_state == ALU);
assign o_debug_flag = r_exmem_result[4:0];
endmodule
