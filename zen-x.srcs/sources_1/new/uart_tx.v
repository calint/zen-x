`timescale 1ns / 1ps
`default_nettype none

module uart_tx (
  input wire rst,
  input wire clk,
  input wire [7:0] data,
  input wire send,
  output reg tx
);

parameter BAUD_RATE = 9600;
parameter CLK_FREQ = 66_000_000;
parameter BIT_TIME = CLK_FREQ / BAUD_RATE;
parameter STOP_BITS = 1;
parameter START_BIT = 0;

localparam STATE_IDLE        = 0;
localparam STATE_START_BIT   = 1;
localparam STATE_DATA_BITS   = 2;
localparam STATE_STOP_BITS_0 = 3;
localparam STATE_STOP_BITS_1 = 4;

reg [2:0] state;
reg [3:0] bit_count;
reg [$ceil($clog2(BIT_TIME)):0] bit_counter;
reg tx_reg;

always @(posedge clk) begin
    if (rst) begin
        state <= STATE_IDLE;
        tx_reg <= 1;
        bit_count <= 0;
        bit_counter <= 0;
        tx <= 1;
    end else begin
        case(state)
        STATE_IDLE: begin
            if (send) begin
                tx_reg <= 0;
                state <= STATE_START_BIT;
                bit_count <= 0;
                bit_counter <= BIT_TIME / 2;
            end else begin
                tx_reg <= 1;
            end
        end
        STATE_START_BIT: begin
            tx_reg <= START_BIT;
            if (bit_counter == 0) begin
                bit_counter <= BIT_TIME;
                state <= STATE_DATA_BITS;
            end
        end
        STATE_DATA_BITS: begin
            tx_reg <= data[bit_count];
            if (bit_counter == 0) begin
                bit_counter <= BIT_TIME;
                bit_count = bit_count + 1;
                if (bit_count == 8) begin
                    state <= STATE_STOP_BITS_0;
                    bit_count <= 0;
                end
            end
        end
        STATE_STOP_BITS_0: begin
            tx_reg <= STOP_BITS;
            if (bit_counter == 0) begin
                bit_counter <= BIT_TIME;
                state <= STATE_STOP_BITS_1;
            end
        end
        STATE_STOP_BITS_1: begin
            tx_reg <= STOP_BITS;
            if (bit_counter == 0) begin
                state <= STATE_IDLE;
                tx_reg <= 1;
            end
        end
        endcase
        
        if (bit_counter > 0) begin
            bit_counter <= bit_counter - 1;
        end
        
        tx <= tx_reg;
    end
end

endmodule

`default_nettype wire