`timescale 1ns / 1ps
`default_nettype none

module uart_tx #(
    parameter CLK_FREQ = 66_000_000,
    parameter BAUD_RATE = 9600
)(
    input wire rst,
    input wire clk,
    input wire [7:0] data,
    input wire go,
    output reg tx,
    output reg bsy
);

localparam BIT_TIME = CLK_FREQ / BAUD_RATE;

localparam STATE_IDLE       = 0;
localparam STATE_START_BIT = 1;
localparam STATE_DATA_BITS  = 2;
localparam STATE_STOP_BIT  = 3;

reg [2:0] state;
reg [3:0] bit_count;

reg [($clog2(BIT_TIME)>0?$clog2(BIT_TIME):1)-1:0] bit_time_counter;

reg go_prv;

always @(negedge clk) begin
    if (rst) begin
        state <= STATE_IDLE;
        bit_count <= 0;
        bit_time_counter <= 0;
        tx <= 1;
        bsy <= 0;
        go_prv <= 0;
    end else begin
        case(state)
        STATE_IDLE: begin
            if (go != go_prv) begin
                go_prv <= go;
                if (go) begin
                    bsy <= 1;
                    bit_count <= 0;
                    bit_time_counter <= BIT_TIME - 1; // ? half the BIT_TIME also works
                    tx <= 0; // start sending start bit
                    state <= STATE_START_BIT;
                end
            end
        end
        STATE_START_BIT: begin
            if (bit_time_counter == 0) begin
                bit_time_counter <= BIT_TIME - 1;
                state <= STATE_DATA_BITS;
                tx <= data[0]; // start sending first bit
            end else begin
                bit_time_counter <= bit_time_counter - 1;
            end
        end
        STATE_DATA_BITS: begin
            if (bit_time_counter == 0) begin
                bit_time_counter <= BIT_TIME - 1;
                bit_count = bit_count + 1; // ? not NBA
                if (bit_count == 8) begin
                    state <= STATE_STOP_BIT;
                    bit_count <= 0;
                    tx <= 1; // start sending stop bit
                end else begin
                    tx <= data[bit_count];
                end
            end else begin
                bit_time_counter <= bit_time_counter - 1;
            end
        end
        STATE_STOP_BIT: begin
            if (bit_time_counter == 0) begin
                state <= STATE_IDLE;
                bsy <= 0;
            end else begin
                bit_time_counter <= bit_time_counter - 1;
            end
        end
        endcase        
    end
end

endmodule

`default_nettype wire