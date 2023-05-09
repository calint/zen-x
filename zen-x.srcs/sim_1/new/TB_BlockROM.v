`timescale 1ns / 1ps
`default_nettype none

module TB_BlockROM;

reg clk = 0;
parameter clk_tk = 10;
always #(clk_tk/2) clk = ~clk;

reg brom_ena;
reg [14:0] brom_addra;
wire [15:0] brom_douta;

BlockROM brom(
  .clka(clk),
  .ena(brom_ena),
  .addra(brom_addra),
  .douta(brom_douta)
);

initial begin

    brom_ena = 1;
    brom_addra = 0;
    #clk_tk
    #clk_tk    
    if (brom_douta == 16'h1090) $display("case 1 passed");
    else $display("case 1 failed - expected 1090, got %d", brom_douta);

    brom_ena = 1;
    brom_addra = 1;
    #clk_tk
    #clk_tk    
    if (brom_douta == 16'h1234) $display("case 2 passed");
    else $display("case 2 failed - expected 1234, got %d", brom_douta);

    $finish;
end

endmodule

`default_nettype wire