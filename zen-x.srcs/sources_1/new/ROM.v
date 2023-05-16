`timescale 1ns / 1ps
`default_nettype none
 
module ROM #(
    parameter ADDR_WIDTH = 16,
    parameter WIDTH = 16
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [WIDTH-1:0] dout
);

reg [WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];

initial begin
    $readmemh("/home/c/w/zen-x/rom.hex", mem);
end

always @(posedge clk) begin
    dout <= mem[addr];
end

endmodule 

`default_nettype wire