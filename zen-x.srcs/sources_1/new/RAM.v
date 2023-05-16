`timescale 1ns / 1ps
`default_nettype none

module RAM #(
    parameter ADDR_WIDTH = 16,
    parameter WIDTH = 16
)(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

reg [WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];

always @(posedge clk) begin
    if (we) begin
        mem[addr] <= din;
        dout <= din;
    end else begin
        dout <= mem[addr];
    end
end

endmodule
`default_nettype wire