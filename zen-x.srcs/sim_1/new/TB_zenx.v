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
    #clk_tk // get rom[0]
    rst = 0;
    
    #clk_tk // got 1090: ldi r1
    #clk_tk // get rom[1]
    #clk_tk // got 0x1234
    #clk_tk // regs[1]=0x1234, get rom[2] 
    if (zx.regs.mem[1]==16'h1234) $display("case 1 passed");
    else $display("case 1 failed. expected 0x1234, got %h", zx.regs.mem[1]); 
    
    #clk_tk // got 2090: ldi r2
    #clk_tk // get rom[3] 
    #clk_tk // got 0xabcd
    #clk_tk // regs[2]=0xabcd, get rom[4]
    if (zx.regs.mem[2]==16'habcd) $display("case 2 passed");
    else $display("case 2 failed. expected 0xabcd, got %h", zx.regs.mem[2]); 
    
    #clk_tk // got 3090: ldi r3
    #clk_tk // get rom[5] 
    #clk_tk // got 0xffff
    #clk_tk // regs[3]=0xffff, get rom[6]
    if (zx.regs.mem[3]==16'hffff) $display("case 3 passed");
    else $display("case 3 failed. expected 0xffff, got %h", zx.regs.mem[3]); 

    #clk_tk // got 0

    $finish;
end

endmodule

`default_nettype wire
