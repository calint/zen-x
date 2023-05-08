`timescale 1ns / 1ps
`default_nettype none

module zenx(
    input wire reset,
    input wire clk_in,
    output wire [3:0] led
);

localparam ROM_ADDR_WIDTH = 14; // 2**14 instructions
localparam RAM_ADDR_WIDTH = 14; // 2**14 data addresses
localparam REGISTERS_ADDR_WIDTH = 4; // 2**4 registers
localparam CALLS_ADDR_WIDTH = 4; // 2**4 stack
localparam REGISTERS_WIDTH = 16; // 16 bit
localparam INSTRUCTION_WIDTH = 16; // 16 bit
    
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

reg [15:0] alu_a = 0;
reg [15:0] alu_b = 0;
reg [2:0] alu_op = 0;
wire [15:0] alu_result;
wire alu_zf;
wire alu_nf;

ALU #(16) alu(
    .op(alu_op),
    .a(alu_a),
    .b(alu_b),
    .result(alu_result),
    .zf(alu_zf),
    .nf(alu_nf)
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
assign led[3] = alu_result[0];

endmodule

`default_nettype wire