`timescale 1ns / 1ps
`default_nettype none
`define DBG

module TB_zenx;

reg clk = 0;
parameter clk_tk = 20;
always #(clk_tk/2) clk = ~clk;
parameter rst_dur = clk_tk*5;

wire [3:0] led;
reg rst;

wire [15:0] debug;
wire [2:0] led_bgr;

zenx zx(
    .rst(rst),
    .clk(clk),
    .led(led),
    .led0_b(led_bgr[2]),
    .led0_g(led_bgr[1]),
    .led0_r(led_bgr[0])
);

initial begin
    rst = 1;
    #rst_dur
    rst = 0;
    
    // rom content:
    // 1033 1234 2033 abcd 3033 ffff 3173 4150 1373 5353 4113 4f13 4303 4323 6443 6663 6483 64a3 61c3 61e3 6fe3 7031 0001 4013 7032 0001 003c 003f
 
    #clk_tk // 1033: ldi r1
    #clk_tk // wait for rom
    #clk_tk // rom: 0x1234
    #clk_tk // regs[1]=0x1234, get rom[2]
    if (zx.regs.mem[1]==16'h1234) $display("case 1 passed");
    else $display("case 1 FAILED. expected 0x1234, got %h", zx.regs.mem[1]); 
    
    #clk_tk // 2033: ldi r2
    #clk_tk // wait for rom 
    #clk_tk // rom: 0xabcd
    #clk_tk // regs[2]=0xabcd, get rom[4]
    if (zx.regs.mem[2]==16'habcd) $display("case 2 passed");
    else $display("case 2 FAILED. expected 0xabcd, got %h", zx.regs.mem[2]); 
    
    #clk_tk // 3033: ldi r3
    #clk_tk // wait for rom 
    #clk_tk // rom: 0xffff
    #clk_tk // regs[3]=0xffff, get rom[6]
    if (zx.regs.mem[3]==16'hffff) $display("case 3 passed");
    else $display("case 3 FAILED. expected 0xffff, got %h", zx.regs.mem[3]); 

    #clk_tk // 1273: st r2 r1
    #clk_tk // ram[r2]=regs[1] => ram[0xabcd]=0x1234

    #clk_tk // 3173: st r1 r3
    #clk_tk // ram[r1]=regs[3] => ram[0x1234]=0xffff
    
    #clk_tk // 6253: ld r2 r6
    #clk_tk // regs[6]=ram[r2] => regs[6]=ram[0xabcd]=0x1234
    if (zx.regs.mem[6]==16'h1234) $display("case 4 passed");
    else $display("case 4 FAILED. expected 0x1234, got %h", zx.regs.mem[4]); 
    
    #clk_tk // 4153: ld r1 r4
    #clk_tk // regs[4]=ram[r1]=ram[0x1234]=0xffff
    if (zx.regs.mem[4]==16'hffff) $display("case 4.1 passed");
    else $display("case 4.1 FAILED. expected 0xffff, got %h", zx.regs.mem[4]); 
    
    #clk_tk // 1373: st r3 r1
    #clk_tk // ram[r3]=regs[1] => ram[0xffff]=0x1234, get rom[8]

    #clk_tk // 5353: ld r3 r5
    #clk_tk // regs[5]=ram[r3] => regs[5]=ram[0xffff]=0x1234, get rom[9]
    if (zx.regs.mem[5]==16'h1234) $display("case 5 passed");
    else $display("case 5 FAILED. expected 0x1234, got %h", zx.regs.mem[5]); 

    // regs        zn:00
    //  0: 0x0000
    //  1: 0x1234
    //  2: 0xabcd
    //  3: 0xffff
    //  4: 0xffff
    //  5: 0x1234
    //  6: 0x1234
    
    #clk_tk // 4113: addi 1 r4
    #clk_tk
    if (zx.regs.mem[4]==0) $display("case 5.1 passed");
    else $display("case 5.1 FAILED. expected 0, got %0d", zx.regs.mem[4]); 

    #clk_tk // 4f13: addi -1 r4
    #clk_tk
    if (zx.regs.mem[4]==-1) $display("case 6 passed");
    else $display("case 6 FAILED. expected -1, got %0d", zx.regs.mem[4]); 
    
    #clk_tk // 4303: add r1 r4
    #clk_tk
    if (zx.regs.mem[4]==-2) $display("case 7 passed");
    else $display("case 7 FAILED. expected -2, got %0d", zx.regs.mem[4]); 

    #clk_tk // 4323: add r3 r4 ; -2-(-1)=-1
    #clk_tk
    if (zx.regs.mem[4]==-1) $display("case 8 passed");
    else $display("case 8 FAILED. expected -1, got %0d", zx.regs.mem[4]); 

    #clk_tk // 6443: or r4 r6 ; 0|0xffff=0xffff
    #clk_tk
    if (zx.regs.mem[6]==-1) $display("case 9 passed");
    else $display("case 9 FAILED. expected -1, got %0d", zx.regs.mem[6]); 

    #clk_tk // 6663: xor r6 r6 ; =0
    #clk_tk
    if (zx.regs.mem[6]==0) $display("case 10 passed");
    else $display("case 10 FAILED. expected 0, got %0d", zx.regs.mem[6]); 

    #clk_tk // 6483: and r4 r6 ; = 0 & 0xffff = 0
    #clk_tk
    if (zx.regs.mem[6]==0) $display("case 11 passed");
    else $display("case 11 FAILED. expected 0, got %0d", zx.regs.mem[6]); 

    // regs
    //  0: 0x0000
    //  1: 0x1234
    //  2: 0xabcd
    //  3: 0xffff
    //  4: 0xffff
    //  5: 0x1234
    //  6: 0x0000
    //  7: 0x0000
    
    #clk_tk // 64a3: not r4 r6 ; = ~0xffff = 0
    #clk_tk
    if (zx.regs.mem[6]==0) $display("case 12 passed");
    else $display("case 12 FAILED. expected 0, got %0d", zx.regs.mem[6]); 

    #clk_tk // 61c3: cp r4 r6 ; => 0x1234
    #clk_tk
    if (zx.regs.mem[6]==16'h1234) $display("case 13 passed");
    else $display("case 13 FAILED. expected 0x1234, got %h", zx.regs.mem[6]);
    
    #clk_tk // 61e3: shf 1 r6 ; 0x1234 >> 1 = 0x091a
    #clk_tk
    if (zx.regs.mem[6]==16'h091a) $display("case 14 passed");
    else $display("case 14 FAILED. expected 0x091a, got %h", zx.regs.mem[6]);
    
    #clk_tk // 6fe3: shf -1 r6 ; 0x091a << 1 = 0x1234
    #clk_tk
    if (zx.regs.mem[6]==16'h1234) $display("case 15 passed");
    else $display("case 15 FAILED. expected 0x1234, got %h", zx.regs.mem[6]);
    
    // flags zn=00
    #clk_tk // 7031: ifz ldi r7; will not execute
    #clk_tk // wait for next instruction
    #clk_tk // rom: 0x0001
    #clk_tk // regs[7]=0x0000
    if (zx.regs.mem[7]==0) $display("case 16 passed");
    else $display("case 16 FAILED. expected 0, got %h", zx.regs.mem[7]); 

    #clk_tk // 4013: addi 0 r4 ; sets zn-flags for r4
    #clk_tk

    #clk_tk // 7032: ifn ldi r7; will execute
    #clk_tk // wait for next instruction
    #clk_tk // rom: 0x0001
    #clk_tk // regs[7]=0x0001
    if (zx.regs.mem[7]==1) $display("case 17 passed");
    else $display("case 17 FAILED. expected 1, got %h", zx.regs.mem[7]); 

    // pc=28, zn=01
    #clk_tk // 003c: skp 3 ; not executed because zn!=00
    #clk_tk // wait for next instruction
    if (zx.pc==29) $display("case 18 passed");
    else $display("case 18 FAILED. expected 29, got %0d", zx.pc);

    #clk_tk // 003f: ifzn skp 3
    #clk_tk // wait for next instruction
    if (zx.pc==29+3) $display("case 19 passed");
    else $display("case 19 FAILED. expected 32, got %0d", zx.pc);
    
    // pc=32 zn=01
    // regs
    //  0: 0x0000
    //  1: 0x1234
    //  2: 0xabcd
    //  3: 0xffff
    //  4: 0xffff
    //  5: 0x1234
    //  6: 0x1234
    //  7: 0x0000
    //  8: 0x0000
    
    #clk_tk // 0038: call 0x0030
    #clk_tk

    // pc=48, zn=00
    if (zx.pc==48) $display("case 20 passed");
    else $display("case 20 FAILED. expected 48, got %0d", zx.pc);
    if (!zx.zn_zf && !zx.zn_nf) $display("case 21 passed");
    else $display("case 21 FAILED. expected 0, 0 got %0d, %0d", zx.zn_zf, zx.zn_nf);
    
    #clk_tk // 8117: addi 1 r8 ret
    #clk_tk //

    // pc=33
    // flags zn=01
    if (zx.pc==33) $display("case 23 passed");
    else $display("case 23 FAILED. expected 33, got %0d", zx.pc);
    if (!zx.zn_zf && zx.zn_nf) $display("case 24 passed");
    else $display("case 24 FAILED. expected 0, 1 got %0d, %0d", zx.zn_zf, zx.zn_nf);
    if (zx.regs.mem[8]==1) $display("case 25 passed");
    else $display("case 25 FAILED. expected 1, got %0d", zx.regs.mem[8]); 
    
    #clk_tk // 010f: skp 2
    #clk_tk //
    if (zx.pc==49) $display("case 26 passed");
    else $display("case 26 FAILED. expected 49, got %0d", zx.pc);
    
    #clk_tk // 001f: skp 1
    #clk_tk // 
    
    // pc=50, zn=01
    #clk_tk // 000f: skp 0 ; hang
    #clk_tk //
     
    #clk_tk   
    $finish;
end

endmodule

`default_nettype wire
