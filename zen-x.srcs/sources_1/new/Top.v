`timescale 1ns / 1ps
`default_nettype none

// ROM files used in simulations

module Top #(
   parameter ROM_FILE = "/home/c/w/zen-x/zen-x.srcs/sim_1/new/TB_Zenx.hex"
// parameter ROM_FILE = "/home/c/w/zen-x/zen-x.srcs/sim_4/new/TB_ZenxHex.hex"
// parameter ROM_FILE = "/home/c/w/zen-x/zen-x.srcs/sim_5/new/TB_ZenxPrint.hex"
// parameter ROM_FILE = "/home/c/w/zen-x/zen-x.srcs/sim_6/new/TB_ZenxInput.hex"
)(
    input wire reset,
    input wire clk_in,
    output wire uart_tx,
    input wire uart_rx,
    input wire btn,
    output wire [3:0] led,
    output wire led0_r,
    output wire led0_g,
    output wire led0_b
);

localparam CLK_FREQ = 66_000_000;
localparam BAUD_RATE = 9600;
// baud rates: 300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400

wire clk_locked;
wire clk;

Clocking clkg (
    .reset(reset),
    .locked(clk_locked),
    .clk_in1(clk_in),
    .clk_out1(clk)
);

Zenx #(
    .ROM_FILE(ROM_FILE),
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) zx (
    .rst(!clk_locked),
    .clk(clk),
    .btn(btn),
    .led(led),
    .led0_r(led0_r),
    .led0_g(led0_g),
    .led0_b(led0_b),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx)
);

endmodule

`default_nettype wire