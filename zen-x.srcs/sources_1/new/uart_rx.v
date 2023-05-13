`timescale 1ns / 1ps
`default_nettype none

module uart_rx #(
    parameter CLK_FREQ = 66_000_000,
    parameter BAUD_RATE = 9600
)(
    input wire rst,
    input wire clk,
    input wire rx,
    input wire go, // start reading next byte
    input wire ack, // enable to acknowledge that data has been read
    output reg [7:0] data,
    output reg dr, // enabled when data is ready
    output reg bsy, // enabled when reading a byte
    output reg [3:0] led,
    output reg led_g
);

localparam BIT_TIME = CLK_FREQ / BAUD_RATE;
localparam STOP_BITS = 1;
localparam START_BIT = 0;

localparam STATE_IDLE         = 0;
localparam STATE_START_BIT    = 1;
localparam STATE_DATA_BITS    = 2;
localparam STATE_STOP_BITS    = 3;
localparam STATE_WAIT_ACK     = 4;
localparam STATE_WAIT_ACK_LOW = 5;

reg [3:0] state;
reg [3:0] bit_count;
reg [$clog2(BIT_TIME)-1:0] bit_counter;
reg rx_reg;
reg [7:0] data_reg;

always @(negedge clk) begin
    if (rst) begin
        state <= STATE_IDLE;
        data_reg <= 0;
        data <= 0;
        bit_count <= 0;
        bit_counter <= 0;
        dr <= 0;
        bsy <= 0;
        led <= 0;
        led_g <= 0;
    end else begin
        led <= state;
        case(state)
        STATE_IDLE: begin
            //led[0] <= 1;
            if (!rx && !go)
                led_g <= 1;
            if (!rx && go) begin
                bsy <= 1;
                state <= STATE_START_BIT;
                bit_count <= 0;
                bit_counter <= BIT_TIME / 2 - 1;  // offset the sample time to the middle of the oversampling
            end
        end
        STATE_START_BIT: begin
            //led[1] <= 1;
            if (bit_counter == 0) begin
                bit_counter <= BIT_TIME - 1;
                state <= STATE_DATA_BITS;
            end
        end
        STATE_DATA_BITS: begin
            //led[2] <= 1;
            if (bit_counter == 0) begin
                data_reg[bit_count] <= rx;
                bit_counter <= BIT_TIME - 1;
                bit_count = bit_count + 1;
                if (bit_count == 8) begin
                    state <= STATE_STOP_BITS;
                    bit_count <= 0;
                end
            end
        end
        STATE_STOP_BITS: begin
            //led[3] <= 1;
            if (bit_counter == 0) begin
                state <= STATE_WAIT_ACK;
                if (rx_reg == STOP_BITS) begin
                    data <= data_reg;
                    bsy <= 0;
                    dr <= 1;
                end
            end
        end
        STATE_WAIT_ACK: begin
            led_g <= 1;
            if (ack) begin
                state <= STATE_WAIT_ACK_LOW;
                dr <= 0;
            end
        end
        STATE_WAIT_ACK_LOW: begin
            if (!ack) begin
                state <= STATE_IDLE;
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

`default_nettype wire