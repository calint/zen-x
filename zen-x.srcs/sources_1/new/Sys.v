`timescale 1ns / 1ps
`default_nettype none

module Sys(
    input wire reset,
    input wire clk_in,
    output wire uart_tx,
    input wire uart_rx,
    input wire [1:0] btn,
    output wire [3:0] led,
    output wire led0_r,
    output wire led0_g,
    output wire led0_b
);

wire clk_locked;
wire clk;

Clocking clkg(
    .reset(reset),
    .locked(clk_locked),
    .clk_in1(clk_in),
    .clk_out1(clk)
);

zenx zx(
    .rst(!clk_locked),
    .clk(clk),
    .btn(btn),
    .led(led),
    .led0_r(led0_r),
    .led0_g(led0_g),
    .led0_b(led0_b)
);

wire [7:0] data;
wire send_data;

uart_rx urx(
  .rst(!clk_locked),
  .clk(clk),
  .data(data),
  .rxd(send_data),
  .rx(uart_rx)
);


uart_tx utx(
  .rst(!clk_locked),
  .clk(clk),
  .data(data),
  .send(send_data),
  .tx(uart_tx)
);

endmodule

`default_nettype wire