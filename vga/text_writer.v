module text_writer #(
    parameter COLS = 80,
    parameter ROWS = 32,
    parameter MARGIN_LEFT = 5
) (
    input wire clk,
    input wire reset_n,
    input wire [31:0] reg0, reg1, reg2, reg3,
    input wire [31:0] reg4, reg5, reg6, reg7,
    input wire [31:0] reg8, reg9, reg10, reg11,
    input wire [31:0] reg12, reg13, reg14, reg15,
    input wire [31:0] reg16, reg17, reg18, reg19,
    input wire [31:0] reg20, reg21, reg22, reg23,
    input wire [31:0] reg24, reg25, reg26, reg27,
    input wire [31:0] reg28, reg29, reg30, reg31,
    output reg [7:0] text_data,
    output reg [11:0] text_addr,
    output reg text_we
);
    // states
    localparam IDLE = 0;
    localparam WRITE_HEADER = 1;
    localparam WRITE_REGISTERS = 2;
    
    reg [2:0] state;
    reg [7:0] char_pos;
    reg [4:0] reg_num;
    reg [5:0] digit_pos;
    reg [31:0] current_value;

    // FSM
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            char_pos <= 0;
            reg_num <= 0;
            digit_pos <= 0;
            text_we <= 0;
        end else begin
            case (state)
                IDLE: begin
                    state <= WRITE_HEADER;
                    char_pos <= 0;
                    text_we <= 1;
                end

                WRITE_HEADER: begin
                    text_we <= 1;
                    text_addr <= MARGIN_LEFT + char_pos;
                    
                    case (char_pos)
                        0:  text_data <= "R";
                        1:  text_data <= "E";
                        2:  text_data <= "G";
                        3:  text_data <= "I";
                        4:  text_data <= "S";
                        5:  text_data <= "T";
                        6:  text_data <= "E";
                        7:  text_data <= "R";
                        8:  text_data <= " ";
                        9:  text_data <= "V";
                        10: text_data <= "A";
                        11: text_data <= "L";
                        12: text_data <= "U";
                        13: text_data <= "E";
                        14: text_data <= "S";
                        default: text_data <= " ";
                    endcase

                    if (char_pos < COLS - 1)
                        char_pos <= char_pos + 1;
                    else begin
                        state <= WRITE_REGISTERS;
                        reg_num <= 0;
                        digit_pos <= 0;
                    end
                end

                WRITE_REGISTERS: begin
                    text_we <= 1;
                    current_value <= 
                        (reg_num == 0)  ? reg0  : (reg_num == 1)  ? reg1  :
                        (reg_num == 2)  ? reg2  : (reg_num == 3)  ? reg3  :
                        (reg_num == 4)  ? reg4  : (reg_num == 5)  ? reg5  :
                        (reg_num == 6)  ? reg6  : (reg_num == 7)  ? reg7  :
                        (reg_num == 8)  ? reg8  : (reg_num == 9)  ? reg9  :
                        (reg_num == 10) ? reg10 : (reg_num == 11) ? reg11 :
                        (reg_num == 12) ? reg12 : (reg_num == 13) ? reg13 :
                        (reg_num == 14) ? reg14 : (reg_num == 15) ? reg15 :
                        (reg_num == 16) ? reg16 : (reg_num == 17) ? reg17 :
                        (reg_num == 18) ? reg18 : (reg_num == 19) ? reg19 :
                        (reg_num == 20) ? reg20 : (reg_num == 21) ? reg21 :
                        (reg_num == 22) ? reg22 : (reg_num == 23) ? reg23 :
                        (reg_num == 24) ? reg24 : (reg_num == 25) ? reg25 :
                        (reg_num == 26) ? reg26 : (reg_num == 27) ? reg27 :
                        (reg_num == 28) ? reg28 : (reg_num == 29) ? reg29 :
                        (reg_num == 30) ? reg30 : reg31;
                    
                    // calculates text address with proper spacing (left margin was nessesary)
                    text_addr <= ((reg_num + 2) * COLS) + MARGIN_LEFT + digit_pos;
                    
                    case (digit_pos)
                        0: begin 
                            text_data <= "R";
                            digit_pos <= digit_pos + 1;
                        end
                        1: begin 
                            text_data <= (reg_num / 10) + "0";
                            digit_pos <= digit_pos + 1;
                        end
                        2: begin 
                            text_data <= (reg_num % 10) + "0";
                            digit_pos <= digit_pos + 1;
                        end
                        3: begin 
                            text_data <= ":";
                            digit_pos <= digit_pos + 1;
                        end
                        4: begin 
                            text_data <= " ";
                            digit_pos <= digit_pos + 1;
                        end
                        // For all cases 5-36 it displays the values of all 32 registers
                        5,6,7,8,9,10,11,12,13,14,15,16,
                        17,18,19,20,21,22,23,24,25,26,27,28,
                        29,30,31,32,33,34,35,36: begin
                            text_data <= current_value[31 - (digit_pos - 5)] ? "1" : "0";
                            digit_pos <= digit_pos + 1;
                        end
                        37: begin
                            if (reg_num < 31) begin
                                reg_num <= reg_num + 1;
                                digit_pos <= 0;
                            end else begin
                                state <= IDLE;
                            end
                        end
                        default: digit_pos <= 0;
                    endcase
                end
            endcase
        end
    end
endmodule