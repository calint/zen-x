`timescale 1ns / 1ps
`default_nettype none

module Sys(
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


wire [15:0] debug;

zenx zx(
    .rst(!clk_locked),
    .clk(clk),
    .led(led),
    .debug(debug)
);

endmodule

`default_nettype wire