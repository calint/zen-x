`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module UartRx #(
    parameter CLK_FREQ = 66_000_000,
    parameter BAUD_RATE = 9600
)(
    input wire rst,
    input wire clk,
    input wire rx,
    input wire go,
    output reg [7:0] data,
    output reg dr // enabled when data is ready
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
    end else begin
        case(state)
        STATE_IDLE: begin
            if (!rx && go) begin // does the cpu wait for data and start bit has started?
                bit_count <= 0;
                if (BIT_TIME == 1) begin
                    // the start bit has been read, jump to data
                    bit_counter <= BIT_TIME - 1; // -1 because one of the ticks has been read before switching state
                    state <= STATE_DATA_BITS;
                end else begin
                     // get sample from half of the cycle
                    bit_counter <= BIT_TIME / 2 - 1; // -1 because one of the ticks has been read before switching state
                    state <= STATE_START_BIT;
                end
            end
        end
        STATE_START_BIT: begin
            if (bit_counter == 0) begin  // no check if rx==0 because there is no error recovery
                bit_counter <= BIT_TIME - 1; // -1 because one of the ticks has been read before switching state
                state <= STATE_DATA_BITS;
            end
        end
        STATE_DATA_BITS: begin
            if (bit_counter == 0) begin
                data_reg[bit_count] <= rx;
                bit_count = bit_count + 1; // ? NBA
                bit_counter <= BIT_TIME - 1; // -1 because one of the ticks has been read before switching state
                if (bit_count == 8) begin
                    bit_count <= 0;
                    state <= STATE_STOP_BITS;
                end
            end
        end
        STATE_STOP_BITS: begin
            if (bit_counter == 0) begin // no check if rx==1 because there is no error recovery
                data <= data_reg;
                dr <= 1;
                state <= STATE_WAIT_GO_LOW;
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
        
    end
end

endmodule

`undef DBG
`default_nettype wire