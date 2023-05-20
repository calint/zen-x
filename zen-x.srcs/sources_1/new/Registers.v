`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Registers #(
    parameter ADDR_WIDTH = 4,
    parameter WIDTH = 16
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] ra1, // register address 1
    input wire [ADDR_WIDTH-1:0] ra2, // register address 2
    input wire [WIDTH-1:0] wd, // data to write to register 'ra2' when 'we' is enabled
    input wire we, // enables write 'wd' to address 'ra2'
    output wire [WIDTH-1:0] rd1, // register data 1
    output wire [WIDTH-1:0] rd2 // register data 2
);

reg signed [WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];

assign rd1 = mem[ra1];
assign rd2 = mem[ra2];

integer i;
initial begin
    for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
        mem[i] = {WIDTH{1'b0}};
    end
end

always @(posedge clk) begin
    `ifdef DBG
        $display("%0t: clk+: Registers (ra1,ra2,rd1,rd2)=(%0h,%0h,%0h,%0h)", $time, ra1, ra2, rd1, rd2);
    `endif

    if (we)
        mem[ra2] <= wd;
end

endmodule

`undef DBG
`default_nettype wire