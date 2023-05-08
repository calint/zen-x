`timescale 1ns / 1ps
`default_nettype none

module zenx(
    input wire reset,
    input wire clk_in,
    output wire [3:0] led,
    output wire [15:0] debug
);

localparam ROM_ADDR_WIDTH = 15; // 2**15 instructions
localparam RAM_ADDR_WIDTH = 16; // 2**16 data addresses
localparam REGISTERS_ADDR_WIDTH = 4; // 2**4 registers
localparam CALLS_ADDR_WIDTH = 4; // 2**4 stack
localparam REGISTERS_WIDTH = 16; // 16 bit
    
wire clk_locked;
wire clk = clk_in;

//Clocking clkg(
//    .reset(reset),
//    .locked(clk_locked),
//    .clk_in(clk_in),
//    .clk_out(clk)
//);

wire [15:0] rom_dat;
wire [15:0] ram_dat;
wire [15:0] alu_result;
wire alu_zf;
wire alu_nf;
wire rom_en;
wire [14:0] rom_addr;
wire ram_en;
wire ram_we;
wire [15:0] ram_addr;
wire [15:0] ram_dat_in;
wire [2:0] alu_op;

BlockROM brom( // 32K x 16b
    .clka(clk),
    .ena(rom_en),
    .addra(rom_addr),
    .douta(rom_dat)
);

reg [15:0] alu_a = 0;
reg [15:0] alu_b = 0;

ALU alu(
    .op(alu_op),
    .a(alu_a),
    .b(alu_b),
    .result(alu_result),
    .zf(alu_zf),
    .nf(alu_nf)
);

BlockRAM bram( // 64K x 16b
    .clka(clk),
    .ena(ram_en),
    .wea(ram_we),
    .addra(ram_addr),
    .dina(ram_dat_in),
    .douta(ram_dat)
);

Control ctrl(
 //   .rst(!clk_locked),
    .rst(reset),
    .clk(clk),
    .rom_dat(rom_dat),
    .ram_dat(ram_dat),
    .alu_result(alu_result),
    .alu_zf(alu_zf),
    .alu_nf(alu_nf),
    .rom_en(rom_en),
    .rom_addr(rom_addr),
    .ram_en(ram_en),
    .ram_we(ram_we),
    .ram_addr(ram_addr),
    .ram_dat_in(ram_dat_in),
    .alu_op(alu_op)
);

assign led[0] = rom_dat[0];
assign led[1] = ram_dat_in[0];
assign led[2] = clk;
assign led[3] = alu_result[0];

endmodule

`default_nettype wire