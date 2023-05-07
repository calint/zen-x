`timescale 1ns / 1ps
`default_nettype none

module TB_BlockRAM;

reg clk = 0;
parameter clk_tk = 10;
always #(clk_tk/2) clk = ~clk;

reg bram_ena;
reg bram_wea;
reg [15:0] bram_addra;
reg [15:0] bram_dina;
wire [15:0] bram_douta;

BlockRAM bram(
  .clka(clk),
  .ena(bram_ena),
  .wea(bram_wea),
  .addra(bram_addra),
  .dina(bram_dina),
  .douta(bram_douta)
);

initial begin

    bram_ena = 1;
    bram_wea = 1;
    bram_addra = 0;
    bram_dina = 16'habcd;
    #clk_tk
    #clk_tk

    bram_ena = 1;
    bram_wea = 1;
    bram_addra = 1;
    bram_dina = 16'hefab;
    #clk_tk
    #clk_tk
    
    bram_ena = 1;
    bram_wea = 0;
    bram_addra = 0;
    #clk_tk
    #clk_tk
    if (bram_douta == 16'habcd) $display("case 1 passed");
    else $display("case 1 failed - expected 0xabcd, got %d", bram_douta);

    bram_ena = 1;
    bram_wea = 0;
    bram_addra = 1;
    #clk_tk
    #clk_tk
    if (bram_douta == 16'hefab) $display("case 2 passed");
    else $display("case 2 failed - expected 0xefab, got %d", bram_douta);

    bram_ena = 0;
    bram_wea = 0;
    bram_addra = 1;
    #clk_tk
    #clk_tk
    if (bram_douta == 16'hefab) $display("case 3 passed");
    else $display("case 3 failed - expected 0xefab, got %d", bram_douta);

    $finish;
end

endmodule

`default_nettype wire