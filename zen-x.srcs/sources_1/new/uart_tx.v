`timescale 1ns / 1ps
`default_nettype none

module uart_tx #(
    parameter CLK_FREQ = 66_000_000,
    parameter BAUD_RATE = 9600)
(
    input wire rst,
    input wire clk,
    input wire [7:0] data,
    input wire tx_go,
    output reg tx,
    output reg tx_done
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
reg tx_reg;

reg tx_go_prv;

always @(posedge clk) begin
    if (rst) begin
        state <= STATE_IDLE;
        tx_reg <= 1;
        bit_count <= 0;
        bit_counter <= 0;
        tx <= 1;
        tx_done <= 0;
        tx_go_prv <= 0;
    end else begin
        case(state)
        STATE_IDLE: begin
            if (tx_go != tx_go_prv) begin
                tx_go_prv <= tx_go;
                if (tx_go) begin
                    tx_reg <= 0;
                    state <= STATE_START_BIT;
                    bit_count <= 0;
                    bit_counter <= BIT_TIME; // ? half the bit_time also works
                end else begin
                    tx_reg <= 1;
                end
            end else begin
                tx_reg <= 1;
            end
        end
        STATE_START_BIT: begin
            tx_done <= 0;
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
                    state <= STATE_STOP_BITS;
                    bit_count <= 0;
                end
            end
        end
        STATE_STOP_BITS: begin
            tx_reg <= STOP_BITS;
            if (bit_counter == 0) begin
                state <= STATE_IDLE;
                tx_reg <= 1;
                tx_done <= 1;
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