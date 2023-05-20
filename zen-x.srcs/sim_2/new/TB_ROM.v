`timescale 1ns / 1ps
`default_nettype none

module TB_ROM;

localparam ROM_FILE = "TB_ROM.hex";

reg clk = 0;
parameter clk_tk = 10;
always #(clk_tk/2) clk = ~clk;

reg [15:0] addr;
wire [15:0] dout;

ROM #(
    .DATA_FILE(ROM_FILE)
) rom(
  .clk(clk),
  .addr(addr),
  .dout(dout)
);

initial begin

    #(clk_tk/2)

    addr = 0;
    #clk_tk
    if (dout == 16'h1033) $display("case 1 passed");
    else $display("case 1 failed - expected 1033, got %h", dout);
 
    addr = 1;
    #clk_tk
    if (dout == 16'h1234) $display("case 2 passed");
    else $display("case 2 failed - expected 0x1234, got %h", dout);
 
    $finish;
end

endmodule

`default_nettype wire