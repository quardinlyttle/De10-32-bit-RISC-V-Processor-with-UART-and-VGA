module vga_display (
    input wire clk,
    input wire reset_n,
    
    input wire [7:0] text_data,
    input wire [11:0] text_addr,
    input wire text_we,
    
    // VGA signals (No touchy)
    output wire vga_hsync,
    output wire vga_vsync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b
);
    parameter COLS = 80;
    parameter ROWS = 32;

    // VGA controller signals
    wire disp_ena;
    wire [31:0] column;
    wire [31:0] row;
    
    // char pos calculation
    wire [6:0] char_col = column[9:3]; // this is taking the 7 bits from 9 to 3
    wire [4:0] char_row = row[8:4];
    wire [2:0] pixel_col = column[2:0];
    wire [3:0] pixel_row = row[3:0];

    // txt buffer to store all the text on the screen
    reg [7:0] text_buffer [0:COLS*ROWS-1];
    
    // Font ROM signals
    wire [11:0] font_addr;
    wire [7:0] font_data;
    
    // if current position is in header (OUTDATED)
    wire is_header = (char_row == 0);

    // ROM addressing
    wire [7:0] char_code = text_buffer[char_row * COLS + char_col];
    assign font_addr = {char_code, pixel_row};
    wire pixel_on = font_data[7 - pixel_col];

    vga_controller vga_ctrl (
        .pixel_clk(clk),
        .reset_n(reset_n),
        .h_sync(vga_hsync),
        .v_sync(vga_vsync),
        .disp_ena(disp_ena),
        .column(column),
        .row(row)
    );

    // declare the font rom
    font_rom font (
        .clk(clk),
        .addr(font_addr),
        .data(font_data)
    );

    // txt buffer write logic
    always @(posedge clk) begin
        if (!reset_n) begin
            integer i;
            for (i = 0; i < COLS*ROWS; i = i + 1)
                text_buffer[i] <= 8'h20; // space char
        end else if (text_we) begin
            text_buffer[text_addr] <= text_data;
        end
    end

    // color gen
    wire [3:0] text_color = pixel_on ? 4'hF : 4'h0;  // we settled on white text on black background
    wire [3:0] header_color = 4'h9;                   // blue header(not used anymore)
    
    // final color calc
    assign vga_r = disp_ena ? (text_color) : 4'h0;
    assign vga_g = disp_ena ? (text_color) : 4'h0;
    assign vga_b = disp_ena ? (text_color) : 4'h0;

    // // final color calc (the header is kinda useless)
    // assign vga_r = disp_ena ? (is_header ? header_color : text_color) : 4'h0;
    // assign vga_g = disp_ena ? (is_header ? header_color : text_color) : 4'h0;
    // assign vga_b = disp_ena ? (is_header ? 4'hF : text_color) : 4'h0;

endmodule
