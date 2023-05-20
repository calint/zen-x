`timescale 1ns / 1ps
`default_nettype none
//`define DBG
 
module ROM #(
    parameter DATA_FILE = "ROM.hex",
    parameter ADDR_WIDTH = 16,
    parameter WIDTH = 16
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [WIDTH-1:0] dout
);

reg [WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];

initial begin
    $readmemh(DATA_FILE, mem);
end

always @(posedge clk) begin
    `ifdef DBG
        $display("  clk: rom: %d:%h", addr, dout);
    `endif
    dout <= mem[addr];
end

endmodule 

`undef DBG
`default_nettype wire