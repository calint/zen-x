`timescale 1ns / 1ps
`default_nettype none

module uart_rx #(
    parameter CLK_FREQ = 66_000_000,
    parameter BAUD_RATE = 9600
)(
    input wire rst,
    input wire clk,
    input wire rx,
    input wire go,
    output reg [7:0] data,
    output reg dr, // enabled when data is ready
    output reg [3:0] led,
    output reg led_g
);

localparam BIT_TIME = CLK_FREQ / BAUD_RATE;

localparam STATE_IDLE         = 0;
localparam STATE_START_BIT    = 1;
localparam STATE_DATA_BITS    = 2;
localparam STATE_STOP_BITS    = 3;
localparam STATE_WAIT_GO_LOW  = 4;

reg [$clog2(5)-1:0] state;
reg [$clog2(9)-1:0] bit_count;
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
        led <= 0;
        led_g <= 0;
    end else begin
        led[2:0] = state;
        case(state)
        STATE_IDLE: begin
            if (!rx && !go)
                led[3] <= 1;
            if (!rx && go) begin
                bit_count <= 0;
                bit_counter <= BIT_TIME / 2 - 1;  // offset the sample time to the middle of the oversampling
                state <= STATE_START_BIT;
            end
        end
        STATE_START_BIT: begin
            if (bit_counter == 0) begin
                bit_counter <= BIT_TIME - 1;
                state <= STATE_DATA_BITS; // ? check rx==0
            end
        end
        STATE_DATA_BITS: begin
            if (bit_counter == 0) begin
                data_reg[bit_count] <= rx;
                bit_counter <= BIT_TIME - 1;
                bit_count = bit_count + 1;
                if (bit_count == 8) begin
                    bit_count <= 0;
                    state <= STATE_STOP_BITS;
                end
            end
        end
        STATE_STOP_BITS: begin
            if (bit_counter == 0) begin
                if (rx_reg == 1) begin
                    data <= data_reg;
                    dr <= 1;
                end
                state <= STATE_WAIT_GO_LOW; // ? even if rx_reg==0 ?
            end
        end
        STATE_WAIT_GO_LOW: begin
            if (!go) begin
                dr <= 0;
                state <= STATE_IDLE;
            end
        end
        endcase
        
        if (bit_counter > 0) begin // ? y this check
            bit_counter <= bit_counter - 1;
        end
        
        rx_reg <= rx;
    end
end

endmodule

`default_nettype wire