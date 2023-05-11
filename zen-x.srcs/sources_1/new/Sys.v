`timescale 1ns / 1ps
`default_nettype none

module Sys(
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

reg [7:0] data_out;
wire [7:0] data_in;
wire rx_done;
reg rx_done_prv;
wire tx_done;
reg tx_go;
reg state; // 0: waiting for rx_done, 1: waiting for tx_done

uart_rx urx(
  .rst(!clk_locked),
  .clk(clk),
  .data(data_in),
  .rx_done(rx_done),
  .rx(uart_rx)
);

uart_tx utx(
  .rst(!clk_locked),
  .clk(clk),
  .data(data_out),
  .tx_go(tx_go),
  .tx(uart_tx),
  .tx_done(tx_done)
);


always @(posedge clk) begin
    if (!clk_locked) begin
        tx_go <= 0;
        rx_done_prv <= 0;
        data_out <= 0;
        state <= 0;
    end else begin
        case(state)
        0: begin
            if (rx_done_prv != rx_done) begin
                rx_done_prv <= rx_done;
                if (rx_done) begin
                    data_out <= data_in;
                    tx_go <= 1;
                    state <= 1;
                end
            end
        end
        1: begin
            if (tx_done) begin
                tx_go <= 0;
                state <= 0;
            end
        end
        endcase
    end
 end

endmodule

`default_nettype wire