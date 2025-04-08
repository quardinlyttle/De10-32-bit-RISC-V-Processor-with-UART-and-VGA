// font ROM module
module font_rom (
    input wire clk,
    input wire [11:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:4095];  // 256 characters * 16 rows = 4096 entries

    initial begin
        // loads file font
        $readmemh("cp866-8x16.hex", rom);
    end

    always @(posedge clk) begin
        data <= rom[addr];
    end
endmodule

