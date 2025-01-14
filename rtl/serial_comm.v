module serial_comm
#(
    parameter SYS_CLK = 50_000_000,
    parameter BAUD_RATE = 115_200
)
(
    input wire clk,
    input wire rst,

    // Receiving Interface
    input wire rx_stream,           // Input serial stream
    output reg [7:0] rx_byte,       // Captured byte from serial
    output wire rx_ready,           // Indicates a valid byte received

    // Transmitting Interface
    output reg tx_stream,           // Output serial stream
    input wire [7:0] tx_byte,       // Byte to transmit
    input wire tx_start,            // Signal to start transmission
    output reg tx_idle              // Indicates ready for next byte
);

    /////////////////////////////
    // Internal Declarations //
    /////////////////////////////

    // Clock enable generator
    localparam SYNC_COUNT = 2;
    localparam OVER_SAMPLING = 16;
    localparam CLK_DIV = SYS_CLK / (OVER_SAMPLING * BAUD_RATE);

    reg [15:0] clk_counter;
    reg clk_enable;

    // RX synchronization and state machine
    reg [SYNC_COUNT-1:0] rx_sync_pipe;
    reg rx_internal;

    localparam RX_IDLE = 0;
    localparam RX_VERIFY_START = 1;
    localparam RX_FETCHING = 2;
    localparam RX_COMPLETE = 3;

    reg [1:0] rx_fsm_state = RX_IDLE;
    reg [4:0] rx_clk_counter;
    reg [2:0] rx_bit_counter;

    reg rx_ready_internal, rx_ready_previous;

    // TX state machine
    localparam TX_IDLE = 0;
    localparam TX_SENDING = 1;

    reg tx_fsm_state = TX_IDLE;
    reg [9:0] tx_shift_register;
    reg [4:0] tx_clk_counter;
    reg [3:0] tx_bit_counter;

    //////////////////////
    // Logic Definitions //
    //////////////////////

    // Clock Divider
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_counter <= 0;
            clk_enable <= 0;
        end else if (clk_counter == CLK_DIV - 1) begin
            clk_counter <= 0;
            clk_enable <= 1;
        end else begin
            clk_counter <= clk_counter + 1;
            clk_enable <= 0;
        end
    end

    // RX Synchronizer
    always @(posedge clk) begin
        if (clk_enable) begin
            {rx_sync_pipe, rx_internal} <= {rx_stream, rx_sync_pipe};
        end
        rx_ready_previous <= rx_ready_internal;
    end

    assign rx_ready = rx_ready_internal & ~rx_ready_previous;

    // RX State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_fsm_state <= RX_IDLE;
            rx_ready_internal <= 0;
            rx_byte <= 0;
        end else if (clk_enable) begin
            case (rx_fsm_state)
                RX_IDLE: begin
                    rx_ready_internal <= 0;
                    if (rx_internal == 0) begin  // Start bit detected
                        rx_fsm_state <= RX_VERIFY_START;
                        rx_clk_counter <= 1;
                    end
                end
                RX_VERIFY_START: begin
                    if (rx_clk_counter == (OVER_SAMPLING >> 1) - 1) begin
                        if (rx_internal == 0) begin
                            rx_fsm_state <= RX_FETCHING;
                            rx_clk_counter <= 0;
                            rx_bit_counter <= 0;
                        end else begin
                            rx_fsm_state <= RX_IDLE; // False start
                        end
                    end else begin
                        rx_clk_counter <= rx_clk_counter + 1;
                    end
                end
                RX_FETCHING: begin
                    if (rx_clk_counter == OVER_SAMPLING - 1) begin
                        rx_clk_counter <= 0;
                        rx_byte <= {rx_internal, rx_byte[7:1]};
                        rx_bit_counter <= rx_bit_counter + 1;
                        if (rx_bit_counter == 7) begin
                            rx_fsm_state <= RX_COMPLETE;
                        end
                    end else begin
                        rx_clk_counter <= rx_clk_counter + 1;
                    end
                end
                RX_COMPLETE: begin
                    if (rx_internal == 1) begin  // Stop bit detected
                        rx_fsm_state <= RX_IDLE;
                        rx_ready_internal <= 1;
                    end
                end
                default: rx_fsm_state <= RX_IDLE;
            endcase
        end
    end

    // TX State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_fsm_state <= TX_IDLE;
            tx_stream <= 1; // Idle line state
            tx_idle <= 1;
        end else begin
            case (tx_fsm_state)
                TX_IDLE: begin
                    tx_stream <= 1; // Idle line state
                    if (tx_start) begin
                        tx_shift_register <= {1'b1, tx_byte, 1'b0}; // Stop bit, data, start bit
                        tx_clk_counter <= 0;
                        tx_bit_counter <= 0;
                        tx_idle <= 0;
                        tx_fsm_state <= TX_SENDING;
                    end
                end
                TX_SENDING: begin
                    if (clk_enable) begin
                        if (tx_clk_counter == OVER_SAMPLING - 1) begin
                            tx_clk_counter <= 0;
                            tx_stream <= tx_shift_register[0];
                            tx_shift_register <= {1'b1, tx_shift_register[9:1]};
                            tx_bit_counter <= tx_bit_counter + 1;
                            if (tx_bit_counter == 9) begin
                                tx_fsm_state <= TX_IDLE;
                                tx_idle <= 1;
                            end
                        end else begin
                            tx_clk_counter <= tx_clk_counter + 1;
                        end
                    end
                end
                default: tx_fsm_state <= TX_IDLE;
            endcase
        end
    end

endmodule