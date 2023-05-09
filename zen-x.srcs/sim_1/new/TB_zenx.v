`timescale 1ns / 1ps
`default_nettype none

module TB_zenx;

reg clk = 0;
parameter clk_tk = 20;
always #(clk_tk/2) clk = ~clk;
parameter rst_dur = clk_tk*5;

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
    #rst_dur
    rst = 0;
    
    #clk_tk // 1090: ldi r1; get rom[1]
    #clk_tk // wait for rom[1]
    #clk_tk // rom: 0x1234
    #clk_tk // regs[1]=0x1234, get rom[2]
    if (zx.regs.mem[1]==16'h1234) $display("case 1 passed");
    else $display("case 1 FAILED. expected 0x1234, got %h", zx.regs.mem[1]); 
    
    #clk_tk // 2090: ldi r2
    #clk_tk // get rom[3] 
    #clk_tk // got 0xabcd
    #clk_tk // regs[2]=0xabcd, get rom[4]
    if (zx.regs.mem[2]==16'habcd) $display("case 2 passed");
    else $display("case 2 FAILED. expected 0xabcd, got %h", zx.regs.mem[2]); 
    
    #clk_tk // 3090: ldi r3
    #clk_tk // get rom[5] 
    #clk_tk // got 0xffff
    #clk_tk // regs[3]=0xffff, get rom[6]
    if (zx.regs.mem[3]==16'hffff) $display("case 3 passed");
    else $display("case 3 FAILED. expected 0xffff, got %h", zx.regs.mem[3]); 

    #clk_tk // 31d0: st r1 r3
    #clk_tk // ram[r1]=regs[3] => ram[0x1234]=0xffff, get rom[7]
    #clk_tk // got 4150: ld r1 r4
    #clk_tk // regs[4]=ram[r1] => regs[4]=ram[0x1234]=0xffff, get rom[9]
    if (zx.regs.mem[4]==16'hffff) $display("case 4 passed");
    else $display("case 4 FAILED. expected 0xffff, got %h", zx.regs.mem[4]); 
    
    #clk_tk // 13d0: st r3 r1
    #clk_tk // ram[r3]=regs[1] => ram[0xffff]=0x1234, get rom[8]

    #clk_tk // 5350: ld r3 r5
    #clk_tk // regs[5]=ram[r3] => regs[5]=ram[0xffff]=0x1234, get rom[9]
    if (zx.regs.mem[5]==16'h1234) $display("case 5 passed");
    else $display("case 5 FAILED. expected 0x1234, got %h", zx.regs.mem[5]); 

    // regs
    //  0: 0x0000
    //  1: 0x1234
    //  2: 0xabcd
    //  3: 0xffff
    //  4: 0xffff
    //  5: 0x1234
    
    #clk_tk // 4110: addi 1 r4
    #clk_tk
    if (zx.regs.mem[4]==0) $display("case 5 passed");
    else $display("case 5 FAILED. expected 0, got %h", zx.regs.mem[4]); 

    #clk_tk // 4f10: addi -1 r4
    #clk_tk
    if (zx.regs.mem[4]==-1) $display("case 6 passed");
    else $display("case 6 FAILED. expected -1, got %h", zx.regs.mem[4]); 
    

    $finish;
end

endmodule

`default_nettype wire
