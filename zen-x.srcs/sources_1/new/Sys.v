`timescale 1ns / 1ps
`default_nettype none

module Sys (
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
// baud rates: 300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400
localparam BAUD_RATE = 300;

wire clk_locked;
wire clk;

Clocking clkg (
    .reset(reset),
    .locked(clk_locked),
    .clk_in1(clk_in),
    .clk_out1(clk)
);

Zenx #(
    CLK_FREQ,
    BAUD_RATE
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