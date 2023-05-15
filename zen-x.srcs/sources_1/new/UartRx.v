`timescale 1ns / 1ps
`default_nettype none

module UartRx #(
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
reg [(BIT_TIME == 1 ? 1 : $clog2(BIT_TIME))-1:0] bit_counter;
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
        case(state)
        STATE_IDLE: begin
            led <= 0;
            if (!rx && !go)
                led[3] <= 1;
            if (!rx && go) begin
                bit_count <= 0;
                if (BIT_TIME == 1) begin
                    // the start bit has been read, jump to data
                    bit_counter <= BIT_TIME - 1; // -1 because one of the ticks has been read before switching state
                    state <= STATE_DATA_BITS;
                end else begin
                     // get sample from half of the cycle
                    bit_counter <= BIT_TIME == 1 ? 0 : BIT_TIME / 2 - 1; // -1 because one of the ticks has been read before switching state
                    state <= STATE_START_BIT;
                end
            end
        end
        STATE_START_BIT: begin
            led <= 1;
            if (bit_counter == 0) begin  // no check if rx==0 because there is no error recovery
                bit_counter <= BIT_TIME - 1; // -1 because one of the ticks has been read before switching state
                state <= STATE_DATA_BITS; // ? check rx==0
            end
        end
        STATE_DATA_BITS: begin
            led <= 2;
            if (bit_counter == 0) begin
                data_reg[bit_count] <= rx;
                bit_count = bit_count + 1;
                bit_counter <= BIT_TIME - 1; // -1 because one of the ticks has been read before switching state
                if (bit_count == 8) begin
                    bit_count <= 0;
                    state <= STATE_STOP_BITS;
                end
            end
        end
        STATE_STOP_BITS: begin
            led <= 3;
            if (bit_counter == 0) begin // no check if rx==1 because there is no error recovery
                data <= data_reg;
                dr <= 1;
                state <= STATE_WAIT_GO_LOW;
            end
        end
        STATE_WAIT_GO_LOW: begin
            led <= 4;            
            if (!go) begin
                dr <= 0;
                state <= STATE_IDLE;
            end
        end
        endcase
        
        if (bit_counter > 0) begin
            bit_counter <= bit_counter - 1;
        end
        
    end
end

endmodule

`default_nettype wire