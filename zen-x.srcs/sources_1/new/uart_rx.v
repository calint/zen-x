`timescale 1ns / 1ps
`default_nettype none

module uart_rx #(
    parameter CLK_FREQ = 66_000_000,
    parameter BAUD_RATE = 9600)
(
  input wire rst,
  input wire clk,
  input wire rx,
  output reg [7:0] data,
  output reg rx_done
);

localparam BIT_TIME = CLK_FREQ / BAUD_RATE;
localparam STOP_BITS = 1;
localparam START_BIT = 0;

localparam STATE_IDLE      = 0;
localparam STATE_START_BIT = 1;
localparam STATE_DATA_BITS = 2;
localparam STATE_STOP_BITS = 3;

reg [2:0] state;
reg [3:0] bit_count;
reg [$clog2(BIT_TIME)-1:0] bit_counter;
reg rx_reg;
reg [7:0] data_reg;

always @(posedge clk) begin
    if (rst) begin
        state <= STATE_IDLE;
        data_reg <= 8'h00;
        bit_count <= 0;
        bit_counter <= 0;
        rx_done <= 0;
    end else begin
        case(state)
        STATE_IDLE: begin
            if (!rx) begin
                rx_done <= 0;
                state <= STATE_START_BIT;
                bit_count <= 0;
                bit_counter <= BIT_TIME / 2;
            end
        end
        STATE_START_BIT: begin
            if (bit_counter == 0) begin
                bit_counter <= BIT_TIME;
                state <= STATE_DATA_BITS;
            end
        end
        STATE_DATA_BITS: begin
            if (bit_counter == 0) begin
                data_reg[bit_count] <= rx;
                bit_counter <= BIT_TIME;
                bit_count = bit_count + 1;
                if (bit_count == 8) begin
                    state <= STATE_STOP_BITS;
                    bit_count <= 0;
                end
            end
        end
        STATE_STOP_BITS: begin
            if (bit_counter == 0) begin
                state <= STATE_IDLE;
                if (rx_reg == STOP_BITS) begin
                    data <= data_reg;
                    rx_done <= 1;
                end
            end
        end
        endcase
        
        if (bit_counter > 0) begin
            bit_counter <= bit_counter - 1;
        end
        
        rx_reg <= rx;
    end
end

endmodule
