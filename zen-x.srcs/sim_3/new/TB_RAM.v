`timescale 1ns / 1ps
`default_nettype none

module TB_RAM;

reg clk = 0;
parameter clk_tk = 10;
always #(clk_tk/2) clk = ~clk;

reg we;
reg [15:0] addr;
reg [15:0] din;
wire [15:0] dout;

RAM ram(
  .clk(clk),
  .we(we),
  .addr(addr),
  .din(din),
  .dout(dout)
);

initial begin

    #(clk_tk/2)

    we = 1;
    addr = 0;
    din = 16'habcd;
    #clk_tk

    we = 1;
    addr = 1;
    din = 16'hefab;
    #clk_tk
    
    we = 0;
    addr = 0;
    #clk_tk
    if (dout == 16'habcd) $display("case 1 passed");
    else $display("case 1 failed - expected 0xabcd, got %d", dout);

    we = 0;
    addr = 1;
    #clk_tk
    if (dout == 16'hefab) $display("case 2 passed");
    else $display("case 2 failed - expected 0xefab, got %d", dout);

    we = 0;
    addr = 1;
    #clk_tk
    if (dout == 16'hefab) $display("case 3 passed");
    else $display("case 3 failed - expected 0xefab, got %d", dout);

    $finish;
end

endmodule

`default_nettype wire