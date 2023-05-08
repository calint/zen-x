`timescale 1ns / 1ps
`default_nettype none

module zenx(
    input wire reset,
    input wire clk_in,
    output wire [3:0] led
    );
    
wire clk_locked;
wire clk;

Clocking clkg(
    .reset(reset),
    .locked(clk_locked),
    .clk_in(clk_in),
    .clk_out(clk)
);

reg brom_ena = 0;
reg [14:0] brom_addra = 0;
wire [15:0] brom_douta;

BlockROM brom( // 32K x 16b
    .clka(clk),
    .ena(brom_ena),
    .addra(brom_addra),
    .douta(brom_douta)
);

reg bram_ena = 0;
reg bram_wea = 0;
reg [15:0] bram_addra = 0;
reg [15:0] bram_dina = 0;
wire [15:0] bram_douta;

BlockRAM bram( // 64K x 16b
    .clka(clk),
    .ena(bram_ena),
    .wea(bram_wea),
    .addra(bram_addra),
    .dina(bram_dina),
    .douta(bram_douta)
);

assign led[0] = brom_douta[0];
assign led[1] = bram_douta[0];
assign led[2] = clk;

endmodule

`default_nettype wire