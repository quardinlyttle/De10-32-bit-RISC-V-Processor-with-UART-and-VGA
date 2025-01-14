module ascii_to_bits_converter (
    input wire clk,                     // Clock signal
    input wire rst,                     // Reset signal

    input wire [7:0] rx_byte,           // Received byte from serial input
    input wire rx_ready,                // Indicates a valid byte received

    output reg [31:0] bit_data,         // Converted 32-bit binary data
    output reg data_ready               // Indicates 32-bit data is ready
);

    // Internal state variables
    reg [4:0] bit_counter;              // Counter to track the number of bits received

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_counter <= 0;
            bit_data <= 0;
            data_ready <= 0;
        end else if (rx_ready) begin
            // Shift in the new bit
            case (rx_byte)
                8'h30: begin // ASCII '0'
                    bit_data <= {bit_data[30:0], 1'b0};
                    bit_counter <= bit_counter + 1;
                end
                8'h31: begin // ASCII '1'
                    bit_data <= {bit_data[30:0], 1'b1};
                    bit_counter <= bit_counter + 1;
                end
                default: begin
                    // Ignore invalid characters
                    bit_data <= bit_data;
                    bit_counter <= bit_counter;
                end
            endcase

            // Check if 32 bits have been received
            if (bit_counter == 31) begin
                data_ready <= 1;
                bit_counter <= 0;      // Reset counter for the next 32 bits
            end else begin
                data_ready <= 0;
            end
        end
    end

endmodule
