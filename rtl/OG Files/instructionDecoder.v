module instructionDecoder(
    input clk,
    input rst,
    input i_flush, //external flush input
    input [31:0] i_instruction, // 32-bit i_instruction input
    output [4:0] o_addr1,
    output [4:0] o_addr2,
    input i_if_ready,
    output o_flush, //internal flush output
    output [31:0] o_operand1,
    output [31:0] o_operand2,
    output [4:0] o_ALUop,
    input [31:0] i_reg_read_data1,
    input [31:0] i_reg_read_data2,
    output o_dec_ins_ready,
    output o_mem_read,
    output o_mem_write,
    output [4:0] o_rd,
    output [9:0] o_debug_flag
); // have to make external connection to regfile will do tomorrow

// ID LOGIC //

localparam ADD  = 4'b0000;
localparam SUB  = 4'b0001;
localparam XOR  = 4'b0010;
localparam OR   = 4'b0011;
localparam AND  = 4'b0100;
localparam SLL  = 4'b0101;
localparam SRL  = 4'b0110;
localparam SRA  = 4'b0111;
localparam SLT  = 4'b1000;
localparam SLTU = 4'b1001;

localparam ADDI  = 5'b1010;  // Add immediate
localparam XORI  = 5'b1011;  // XOR immediate
localparam ORI   = 5'b1100;  // OR immediate
localparam ANDI  = 5'b1101;  // AND immediate
localparam SLLI  = 5'b1110;  // Shift left logical immediate
localparam SRLI  = 5'b1111;  // Shift right logical immediate
localparam SRAI  = 5'b10000; // Shift right arithmetic immediate
localparam SLTI  = 5'b10001; // Set less than immediate
localparam SLTIU = 5'b10010; // Set less than immediate unsigned
localparam SW = 5'b10100; //STORE

reg [31:0] r_id_reg = 0; //hold the instruction
reg r_id_ready = 0;
wire r_decode_fin;
reg r_flush_sig = 0;
reg [1:0] r_decode_fin_delay = 2'b0;
reg [1:0] r_if_ready_delay = 2'b0;
reg [1:0] r_id_ready_delay = 2'b0;
reg r_fin_flag = 0;
wire r_decoded_ins_ready;
reg [6:0] r_op_code = 0;
reg [4:0] rd = 0;        // Destination register (bits 11:7, for R/I-type)
reg [2:0] funct3 = 0;    // Function3 field (bits 14:12)
reg [4:0] rs1 = 0;       // Source register 1 (bits 19:15)
reg [4:0] rs2 = 0;       // Source register 2 (bits 24:20, for R/S-type)
reg [6:0] funct7 = 0;    // Function7 field (bits 31:25, for R-type)
reg [11:0] imm = 0;       // Immediate value (12 bits, for I/S-type)
reg r_idex_reg_occupied = 0;
reg r_idex_reg_occupied_pulse = 0;
//ex
reg [6:0] r_ex_op_code = 0;
reg [4:0] ex_rd = 0;        // Destination register (bits 11:7, for R/I-type)
reg [2:0] ex_funct3 = 0;    // Function3 field (bits 14:12)
reg [4:0] ex_rs1 = 0;       // Source register 1 (bits 19:15)
reg [4:0] ex_rs2 = 0;       // Source register 2 (bits 24:20, for R/S-type)
reg [6:0] ex_funct7 = 0;    // Function7 field (bits 31:25, for R-type)
reg [11:0] ex_imm = 0;       // Immediate value (12 bits, for I/S-type)
reg r_mem_read = 0;
reg r_mem_write = 0;
reg r_idex_mem_read = 0;
reg r_idex_mem_write = 0;
reg [4:0] r_idex_rd = 0;
// hold
reg [6:0] r_ex_hold_op_code = 0;
reg [4:0] ex_hold_rd = 0;        // Destination register (bits 11:7, for R/I-type)
reg [2:0] ex_hold_funct3 = 0;    // Function3 field (bits 14:12)
reg [4:0] ex_hold_rs1 = 0;       // Source register 1 (bits 19:15)
reg [4:0] ex_hold_rs2 = 0;       // Source register 2 (bits 24:20, for R/S-type)
reg [6:0] ex_hold_funct7 = 0;    // Function7 field (bits 31:25, for R-type)
reg [11:0] ex_hold_imm = 0;       // Immediate value (12 bits, for I/S-type)
reg [9:0] DEBUG_FLAG = 9'b0;

parameter IDLE_ID = 2'b00, 
          STORE = 2'b01,
          FLUSH = 2'b10;

reg [1:0] curr_id_state, next_id_state;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_flush_sig <= 1'b0;
    end else begin
        // Combine all conditions for setting r_flush_sig
        if (curr_id_state == FLUSH) begin
            r_flush_sig <= 1'b1;
        end else begin
            r_flush_sig <= 1'b0;
        end
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) curr_id_state <= IDLE_ID;
    else curr_id_state <= next_id_state;
end
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_decode_fin_delay <= 2'b0;
        r_if_ready_delay <= 2'b00;
    end
    else begin
        r_decode_fin_delay <= {r_decode_fin_delay[0], r_decode_fin};
        r_if_ready_delay <= {r_if_ready_delay[0], i_if_ready};
        r_id_ready_delay <= {r_id_ready_delay[0], r_id_ready};
    end
end
always @(*) begin
    next_id_state = curr_id_state;
    case (curr_id_state)
        IDLE_ID: begin
            if (r_if_ready_delay == 2'b01) next_id_state = STORE;
        end

        STORE: begin
            if (r_decode_fin_delay == 2'b01) next_id_state = FLUSH;
        end

        FLUSH: begin
            next_id_state = IDLE_ID;
        end
    endcase
end

wire [4:0] w_addr1;
wire [4:0] w_addr2;
wire [31:0] w_operand1;
wire[31:0] w_operand2;

reg [31:0] r_operand1;
reg [31:0] r_operand2;
reg [4:0] r_ALUop;

reg [31:0] r_idex_operand1;
reg [31:0] r_idex_operand2;
reg [4:0] r_idex_ALUop;

assign o_addr1 = rs1;
assign o_addr2 = rs2;

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_id_reg <= 32'b0;

    end else begin
        case (curr_id_state)
            IDLE_ID: begin
                r_id_reg <= r_id_reg;
            end

            STORE: begin
                r_id_reg <= i_instruction; // Latch the instruction
                r_id_ready <= 1'b1;

            end

            FLUSH: begin
                r_id_reg <= r_id_reg;
                r_id_ready <= 1'b0;
                
            end
        endcase
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        r_idex_reg_occupied_pulse <= 1'b0;
    end else begin
        r_idex_reg_occupied_pulse <= r_decoded_ins_ready && !r_idex_reg_occupied;
    end
end
//decoder logic
parameter IDLE_DEC = 3'b00, 
          SPLIT = 3'b01,
          DECODE = 3'b010,
          PASS = 3'b011;

reg [2:0] curr_dec_state, next_dec_state;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        curr_dec_state <= IDLE_DEC;
    end else begin
        curr_dec_state <= next_dec_state;
    end
end


always @(*) begin
    next_dec_state = curr_dec_state;
    case (curr_dec_state)
        IDLE_DEC: begin
           if (r_id_ready_delay == 2'b01) next_dec_state = SPLIT;
        end

        SPLIT: begin
            // decode in one clk cycle
            // instead of next clk cylce might have to do more register handshaking
            next_dec_state = DECODE;
        end

        DECODE: begin
            if (r_idex_reg_occupied_pulse) 
                next_dec_state = PASS;
            else
                next_dec_state = DECODE; // Stay in FETCH if condition not met

        end

        PASS: begin
            // next state idle_dec
            // PASS will hold the values
            next_dec_state = IDLE_DEC;
        end

    endcase
end



always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_op_code <= 7'b0;
        rd     <= 0;  // Destination register
        rs2    <= 0;// Source register 2
        funct7 <= 0;// funct7
        imm    <= 0;    
        r_mem_read <= 0;
        r_mem_write <= 0;
    end else begin
        case (curr_dec_state)
            IDLE_DEC: begin
                r_op_code <= r_id_reg[6:0];
                funct3 <= r_id_reg[14:12];// funct3 (bits 14:12)
                rs1    <= r_id_reg[19:15];// rs1 (bits 19:15)
            end

            SPLIT: begin
                r_op_code <= r_op_code;
                funct3 <= funct3;// funct3 (bits 14:12)
                rs1    <= rs1;// rs1 (bits 19:15)
                case (r_op_code)
                    7'b0110011: begin //r-type
                        rd     <= r_id_reg [11:7];
                        rs2 <= r_id_reg [24:20];
                        funct7 <= r_id_reg [31:25];
                        imm = 12'b0;
                    end

                    7'b0010011: begin //i-type
                        rd     <= r_id_reg[11:7];  // Destination register
                        imm    <= r_id_reg[31:20];// Immediate value (sign-extended)
                        rs2    <= 5'b0;               // No rs2 for I-type
                        funct7 <= 7'b0;               // No funct7 for I-type
                    end

                    7'b0000011: begin //i-type
                        rd     <= r_id_reg[11:7];  // Destination register
                        imm    <= r_id_reg[31:20];// Immediate value (sign-extended)
                        rs2    <= 5'b0;               // No rs2 for I-type
                        funct7 <= 7'b0;               // No funct7 for I-type
                    end

                    7'b0100011: begin //s-type
                        rd     <= 0;               // No destination register for S-type
                        rs2    <= r_id_reg[24:20];// Source register 2
                        imm    <= {r_id_reg[31:25], r_id_reg[11:7]}; // Immediate value (split)
                        funct7 <= 7'b0;               // No funct7 for S-type
                    end

                endcase
            end

            DECODE: begin
                case(r_op_code)
                    7'b0110011: begin
                        r_operand1 <= i_reg_read_data1;
                        r_operand2 <= i_reg_read_data2;
                        r_mem_read <= 1'b0;
                        r_mem_write <= 1'b0;
                        case ({funct7, funct3})
                            {7'b0000000, 3'b000}: r_ALUop = ADD;  // ADD
                            {7'b0100000, 3'b000}: r_ALUop = SUB;  // SUB
                            {7'b0000000, 3'b100}: r_ALUop = XOR;  // XOR
                            {7'b0000000, 3'b110}: r_ALUop = OR;   // OR
                            {7'b0000000, 3'b111}: r_ALUop = AND;  // AND
                            {7'b0000000, 3'b001}: r_ALUop = SLL;  // SLL
                            {7'b0000000, 3'b101}: r_ALUop = SRL;  // SRL
                            {7'b0100000, 3'b101}: r_ALUop = SRA;  // SRA
                            {7'b0000000, 3'b010}: r_ALUop = SLT;  // SLT
                            {7'b0000000, 3'b011}: r_ALUop = SLTU; // SLTU
                            default: r_ALUop = 4'b1111;
                        endcase
                    end

                    7'b0010011: begin //i-type
                        r_operand2 <= imm;
                        r_operand1 <= i_reg_read_data1;
                        r_mem_read <= 1'b0;
                        r_mem_write <= 1'b0;
                        case(funct3)
                                3'b000: r_ALUop = ADDI;  // ADDI (addition with immediate)
                                3'b100: r_ALUop = XORI;  // XORI (XOR with immediate)
                                3'b110: r_ALUop = ORI;   // ORI (OR with immediate)
                                3'b111: r_ALUop = ANDI;  // ANDI (AND with immediate)
                                3'b001: r_ALUop = SLLI;  // SLLI (shift left logical immediate)
                                3'b101: begin
                                    case (funct7[6:1])    // Using funct7[6:1] to distinguish SRLI/SRAI
                                        6'b000000: r_ALUop = SRLI;  // SRLI (shift right logical immediate)
                                        6'b010000: r_ALUop = SRAI;  // SRAI (shift right arithmetic immediate)
                                        default: r_ALUop = 4'b1111; // Undefined operation
                                    endcase
                                end
                                3'b010: r_ALUop = SLTI;  // SLTI (set less than immediate)
                                3'b011: r_ALUop = SLTIU; // SLTIU (set less than immediate unsigned)
                                default: r_ALUop = 4'b1111; // Undefined operation
                        endcase
                    end

                    7'b0000011: begin //i-type load
                        r_operand2 <= imm;
                        r_operand1 <= i_reg_read_data2;
                        r_mem_read <= 1'b1;
                        r_mem_write <= 1'b0;

                        r_ALUop = ADDI;  // ADDI (addition with immediate)
                    end

                    7'b0100011: begin //s-type store
                        r_operand2 <= i_reg_read_data2;
                        r_mem_read <= 1'b0;
                        r_mem_write <= 1'b1;
                        rd     <= i_reg_read_data1[4:0] + imm[4:0];
                        
                        r_ALUop = SW;  // ADDI (addition with immediate)
                    end
                endcase
            end

            PASS: begin
                //pass the values to ID/EX pipeline by holding these values until
                r_idex_ALUop <= r_ALUop;
                r_idex_operand1 <= r_operand1;
                r_idex_operand2 <= r_operand2;
                r_idex_mem_read <= r_mem_read;
                r_idex_mem_write <= r_mem_write;
                r_idex_rd <= rd;
            end
        endcase
    end
end

// IDEX //
parameter IDLE_IDEX = 2'b00, 
          STORE_IDEX = 2'b01;

reg [1:0] curr_idex_state, next_idex_state;

always @(posedge clk or negedge rst) begin
    if (!rst) curr_idex_state <= IDLE_IDEX;
    else curr_idex_state <= next_idex_state;
end

always @(*) begin
    next_idex_state = curr_idex_state;
    case (curr_idex_state)
        IDLE_IDEX: begin
            if (r_decoded_ins_ready == 1'b1) next_idex_state = STORE_IDEX; //limit to 8 later
        end

        STORE_IDEX: begin
            if (i_flush == 1'b1) next_idex_state = IDLE_IDEX; //if ID in decoder module raises high signal
            // hold onto r_if_reg value til then
            // flush coming all the way from controlUnit
        end
    endcase
end

always @(posedge clk or negedge rst) begin 
    if (!rst) begin
        r_idex_reg_occupied <= 1'b0;

    end else begin
        case (curr_idex_state)
            IDLE_IDEX: begin
                r_idex_reg_occupied <= 1'b0;
            end
            STORE_IDEX: begin //make flush a handshake signal
                r_idex_reg_occupied <= 1'b1; // signal to the decoder that data is ready

            end
        endcase
    end
end
//r_ex_hold_op_code
// ex_hold_rd
// ex_hold_funct3
// ex_hold_rs1
// ex_hold_rs2
// ex_hold_funct7
// ex_hold_imm

// ID/EX PIPELINE LOGIC //

//r_ex_hold_op_code
// ex_hold_rd
// ex_hold_funct3
// ex_hold_rs1
// ex_hold_rs2
// ex_hold_funct7
// ex_hold_imm
assign o_flush = r_flush_sig;
assign o_operand1 = r_idex_operand1;
assign o_operand2 = r_idex_operand2;
assign o_ALUop = r_idex_ALUop;
assign o_dec_ins_ready = r_idex_reg_occupied;
assign o_mem_read = r_idex_mem_read;
assign o_mem_write = r_idex_mem_write;
assign o_rd = r_idex_rd;
assign r_decode_fin = (curr_dec_state == PASS);
assign r_decoded_ins_ready = (curr_dec_state == DECODE);
assign o_debug_flag = r_idex_rd;
endmodule