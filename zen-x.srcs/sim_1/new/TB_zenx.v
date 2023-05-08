`timescale 1ns / 1ps
`default_nettype none

module TB_zenx;

reg clk = 0;
parameter clk_tk = 10;
always #(clk_tk/2) clk = ~clk;

wire [3:0] led;
reg rst;

wire [15:0] debug;

zenx zx(
    .rst(rst),
    .clk(clk),
    .led(led),
    .debug(debug)
);

initial begin
    rst = 1;
    #clk_tk
    #clk_tk
    #clk_tk
    #clk_tk
    rst = 0;
    
    // rom read
    #clk_tk;
    #clk_tk;
    if (zx.ctrl.rom_dat==16'h105b) $display("case 1 passed");
    else $display("case 1 failed. expected 0x1056, got %h", zx.ctrl.rom_dat); 
    
    // ram write
    #clk_tk;
    #clk_tk;
    
    // rom read
    #clk_tk;
    #clk_tk;
    if (zx.ctrl.rom_dat==16'h1234) $display("case 2 passed");
    else $display("case 2 failed. expected 0x1234, got %h", zx.ctrl.rom_dat); 
    
    // ram write
    #clk_tk;
    #clk_tk;

    // rom read
    #clk_tk;
    #clk_tk;
    if (zx.ctrl.rom_dat==16'habcd) $display("case 3 passed");
    else $display("case 3 failed. expected 0xabcd, got %h", zx.ctrl.rom_dat); 
    
    // ram write
    #clk_tk;
    #clk_tk;

    $finish;
end

endmodule

`default_nettype wire
