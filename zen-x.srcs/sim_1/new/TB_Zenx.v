`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module TB_Zenx;

localparam ROM_FILE = "/home/c/w/zen-x/zen-x.srcs/sim_1/new/rom-tb-zenx.hex";
localparam CLK_FREQ = 66_000_000;
localparam BAUD_RATE = CLK_FREQ >> 1; // may be CLK_FREQ
localparam UART_TICKS_PER_BIT = CLK_FREQ / BAUD_RATE;

localparam clk_tk = 16;
//parameter clk_tk = 1_000_000_000 / CLK_FREQ;
// 100+ns of power-on delay in Verilog simulation due to the under-the-hood assertion of Global Set/Reset signal.
localparam rst_dur = 200;

reg clk = 0;
always #(clk_tk/2) clk = ~clk;

reg rst = 1;

wire [3:0] led;
wire [2:0] led_bgr;
reg btn = 0;

wire uart_tx;
reg uart_rx = 1;

integer i;

Zenx #(
    ROM_FILE,
    CLK_FREQ,
    BAUD_RATE
) zx (
    .rst(rst),
    .clk(clk),
    .btn(btn),
    .led(led),
    .led0_b(led_bgr[2]),
    .led0_g(led_bgr[1]),
    .led0_r(led_bgr[0]),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx)
);

initial begin
    $display("ROM '%s'", ROM_FILE);
    #rst_dur
    rst = 0;
    
    #clk_tk // 1033: ldi r1
    #clk_tk // wait for rom
    #clk_tk // 0x1234
    #clk_tk // regs[1]=0x1234
    if (zx.regs.mem[1]==16'h1234) $display("case 1 passed");
    else $display("case 1 FAILED. expected 0x1234, got %h", zx.regs.mem[1]); 
    
    #clk_tk // 2033: ldi r2
    #clk_tk // wait for rom 
    #clk_tk // 0xabcd
    #clk_tk // regs[2]=0xabcd
    if (zx.regs.mem[2]==16'habcd) $display("case 2 passed");
    else $display("case 2 FAILED. expected 0xabcd, got %h", zx.regs.mem[2]); 
    
    #clk_tk // 3033: ldi r3
    #clk_tk // wait for rom 
    #clk_tk // 0xffff
    #clk_tk // regs[3]=0xffff
    if (zx.regs.mem[3]==16'hffff) $display("case 3 passed");
    else $display("case 3 FAILED. expected 0xffff, got %h", zx.regs.mem[3]); 

    #clk_tk // 1273: st r2 r1
    #clk_tk // ram[r2]=regs[1] => ram[0xabcd]=0x1234

    #clk_tk // 3173: st r1 r3
    #clk_tk // ram[r1]=regs[3] => ram[0x1234]=0xffff
    
    #clk_tk // 6253: ld r2 r6
    #clk_tk // regs[6]=ram[r2] => regs[6]=ram[0xabcd]=0x1234
    if (zx.regs.mem[6]=='h1234) $display("case 4 passed");
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
    
    #clk_tk // 4013: addi 0 r4
    #clk_tk
    if (zx.regs.mem[4]==0) $display("case 5.1 passed");
    else $display("case 5.1 FAILED. expected 0, got %0d", zx.regs.mem[4]); 

    #clk_tk // 4f13: addi -1 r4
    #clk_tk
    if (zx.regs.mem[4]==-1) $display("case 6 passed");
    else $display("case 6 FAILED. expected -1, got %0d", zx.regs.mem[4]); 
    
    #clk_tk // 4303: add r3 r4
    #clk_tk
    if (zx.regs.mem[4]==-2) $display("case 7 passed");
    else $display("case 7 FAILED. expected -2, got %0d", zx.regs.mem[4]); 

    #clk_tk // 4323: sub r3 r4 ; -2-(-1)=-1
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
    
    #clk_tk // 60e3: shf 0 r6 ; 0x1234 >> 1 = 0x091a
    #clk_tk
    if (zx.regs.mem[6]==16'h091a) $display("case 14 passed");
    else $display("case 14 FAILED. expected 0x091a, got %h", zx.regs.mem[6]);
    
    #clk_tk // 6fe3: shf -1 r6 ; 0x091a << 1 = 0x1234
    #clk_tk
    if (zx.regs.mem[6]==16'h1234) $display("case 15 passed");
    else $display("case 15 FAILED. expected 0x1234, got %h", zx.regs.mem[6]);
    
    // pc=23, zn=00
    #clk_tk // 7031: ifz ldi r7 ; will not execute
//    #clk_tk // wait for rom
//    #clk_tk // 0x0001
    #clk_tk // regs[7]=0x0000 ; will not load
    if (zx.regs.mem[7]==0) $display("case 16 passed");
    else $display("case 16 FAILED. expected 0, got %h", zx.regs.mem[7]); 

    // pc=25, zn=01
    #clk_tk // 44c3: cp r4 r4 ; sets zn-flags for r4
    #clk_tk

    // pc=26, zn=01
    #clk_tk // 7032: ifn ldi r7; will execute
    #clk_tk // wait for rom
    #clk_tk // 0x0001
    #clk_tk // regs[7]=0x0001
    if (zx.regs.mem[7]==1) $display("case 17 passed");
    else $display("case 17 FAILED. expected 1, got %h", zx.regs.mem[7]); 

    // pc=28, zn=01
    #clk_tk // 004c: ifp jmp 4 ; will not execute because zn!=00
    #clk_tk // wait for rom
    if (zx.pc==29) $display("case 18 passed");
    else $display("case 18 FAILED. expected 29, got %0d", zx.pc);

    // pc=29, zn=01
    #clk_tk // 003f: ifn jmp 3
    #clk_tk // wait for rom
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
    #clk_tk // 003b: call 0x0030
    #clk_tk
    // pc=48, zn=00    
    if (zx.pc==48) $display("case 20 passed");
    else $display("case 20 FAILED. expected 48, got %0d", zx.pc);
    if (zx.cs.pc_out==32) $display("case 21.1 passed");
    else $display("case 21.1 FAILED. expected 32 got %0d", zx.cs.pc_out);
    if (!zx.zn_zf && !zx.zn_nf) $display("case 21 passed");
    else $display("case 21 FAILED. expected 0, 0 got %0d, %0d", zx.zn_zf, zx.zn_nf);
    if (!zx.cs.zf_out && zx.cs.nf_out) $display("case 22 passed");
    else $display("case 22 FAILED. expected 0, 1 got %0d, %0d", zx.cs.zf_out, zx.cs.nf_out);
    
    #clk_tk // 8117: addi 0 r8 ret
    #clk_tk //
    // pc=33, zn=01
    if (zx.pc==33) $display("case 23 passed");
    else $display("case 23 FAILED. expected 33, got %0d", zx.pc);
    if (!zx.zn_zf && zx.zn_nf) $display("case 24 passed");
    else $display("case 24 FAILED. expected 0, 1 got %0d, %0d", zx.zn_zf, zx.zn_nf);
    if (zx.regs.mem[8]==1) $display("case 25 passed");
    else $display("case 25 FAILED. expected 1, got %0d", zx.regs.mem[8]); 
    
    #clk_tk // 0048: ifp call 0x0040 ; not executed zn=01!=00
    #clk_tk //
    if (zx.pc==34) $display("case 25.1 passed");
    else $display("case 25.1 FAILED. expected 34, got %0d", zx.pc);

    #clk_tk // 0049: ifz call 0x0040 ; not executed zn=01!=10
    #clk_tk //
    if (zx.pc==35) $display("case 25.2 passed");
    else $display("case 25.2 FAILED. expected 35, got %0d", zx.pc);

    #clk_tk // 9030: ifp ldi r9, 0x0040 ; not executed zn=01!=00
    #clk_tk // 0x0040
    if (zx.regs.mem[9]==0) $display("case 25.3 passed");
    else $display("case 25.3 FAILED. expected 0, got %0d", zx.regs.mem[9]);

    #clk_tk // 9031: ifz ldi r9, 0x0040 ; not executed zn=01!=10
    #clk_tk // 0x0040
    if (zx.regs.mem[9]==0) $display("case 25.4 passed");
    else $display("case 25.4 FAILED. expected 0, got %0d", zx.regs.mem[9]);
    
    #clk_tk // 00ac: ifp jmp 0x00a ; not executed zn=01!=00
    #clk_tk //
    if (zx.pc==40) $display("case 25.5 passed");
    else $display("case 25.5 FAILED. expected 40, got %0d", zx.pc);

    #clk_tk // 009d: ifz jmp 0x009 ; not executed zn=01!=10
    #clk_tk //
    if (zx.pc==41) $display("case 26 passed");
    else $display("case 26 FAILED. expected 41, got %0d", zx.pc);

    // pc=41 zn=01
    // regs
    //  0: 0x0000
    //  1: 0x1234
    //  2: 0xabcd
    //  3: 0xffff
    //  4: 0xffff
    //  5: 0x1234
    //  6: 0x1234
    //  7: 0x0001
    //  8: 0x0001
    #clk_tk // 005a: ifn call 0x0050
    #clk_tk
    if (zx.pc==80) $display("case 26.1 passed");
    else $display("case 26.1 FAILED. expected 80, got %0d", zx.pc);

    // pc=80 zn=00
    #clk_tk // 006b: call 0x0060
    #clk_tk
    if (zx.pc==96) $display("case 26.2 passed");
    else $display("case 26.2 FAILED. expected 96, got %0d", zx.pc);

    // pc=96 zn=00
    #clk_tk // 8116: ifn addi 1 r8 ret ; not executed
    #clk_tk
    if (zx.regs.mem[8]==1) $display("case 26.3 passed");
    else $display("case 26.3 FAILED. expected 1, got %0d", zx.regs.mem[8]);

    // pc=97 zn=00
    #clk_tk // 8115: ifz addi 1 r8 ret ; not executed
    #clk_tk
    if (zx.regs.mem[8]==1) $display("case 27.3 passed");
    else $display("case 27.3 FAILED. expected 1, got %0d", zx.regs.mem[8]);

    // pc=98 zn=00
    #clk_tk // 8114: ifp addi 1 r8 ret
    #clk_tk
    if (zx.regs.mem[8]==3) $display("case 27.4 passed");
    else $display("case 27.4 FAILED. expected 3, got %0d", zx.regs.mem[8]);
    if (zx.pc==81) $display("case 27.5 passed");
    else $display("case 27.5 FAILED. expected 81, got %d", zx.pc);

    // pc=81 zn=00
    #clk_tk // 8117: addi 1 r8 ret
    #clk_tk
    if (zx.regs.mem[8]==5) $display("case 27.4 passed");
    else $display("case 27.4 FAILED. expected 5, got %0d", zx.regs.mem[8]);
    if (!zx.zn_zf && zx.zn_nf) $display("case 27.5 passed");
    else $display("case 27.5 FAILED. expected 0, 1 got %0d, %0d", zx.zn_zf, zx.zn_nf);

    // pc=42 zn=01
    #clk_tk // 007f: jmp 0x007
    #clk_tk //
    if (zx.pc==49) $display("case 28 passed");
    else $display("case 28 FAILED. expected 49, got %0d", zx.pc);

    
    // pc=49, zn=01
    // transmit "HELLO "  
    for (i = 0; i < 125 * UART_TICKS_PER_BIT; i = i + 1) begin
        #clk_tk;
    end
    
    // receive 0b0101_0101
    uart_rx = 1; // idle
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0; // start bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // stop bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // idle
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    if (zx.regs.mem[10]==16'b0101_0101) $display("case 29 passed");
    else $display("case 29 FAILED. expected 0x0055, got %0h", zx.regs.mem[10]);
    
    for (i = 0; i < 125 * UART_TICKS_PER_BIT; i = i + 1) begin
        #clk_tk;
    end

    for (i = 0; i < 125 * UART_TICKS_PER_BIT; i = i + 1) begin
        #clk_tk;
    end
    
    $finish;
end

endmodule
/*
    ldi 0x1234 r1     # r1=0x1234
    ldi 0xabcd r2     # r2=0xabcd
    ldi 0xffff r3     # r3=0xffff
    st r2 r1          # ram[0xabcd]=0x1234
    st r1 r3          # ram[0x1234]=0xffff
    ld r2 r6          # r6=ram[0xabcd] == 0x1234
    ld r1 r4          # r4=ram[0x1234] == 0xffff
    st r3 r1          # ram[0xffff]=0x1234
    ld r3 r5          # r5=ram[0xffff] == 0x1234
    addi 1 r4         # r4 == 0
    addi -1 r4        # r4 == 0xffff
    add r3 r4         # r4 == 0xfffe
    sub r3 r4         # r4 == 0xffff
    or r4 r6          # r6 == 0xffff
    xor r6 r6         # r6 == 0
    and r4 r6         # r6 == 0
    not r4 r6         # r6 == 0
    cp r1 r6          # r6 == 0x1234
    shf 1 r6          # r6 == 0x0910
    shf -1 r6         # r6 = 0x1234
    ifz ldi 0x0001 r7 # z!=1 => does not execute
    cp r4 r4          # r4 = 0xffff
    ifn ldi 0x0001 r7 # n==1 r7=0x0001
    ifp jmp lbl1      # zn!=00 => does not execute
    jmp lbl1          # 
    0 0               # padding 

lbl1:
    call x0030
    ifp call x0040
    ifz call x0040
    ifp ldi 0x0040 r9
    ifz ldi 0x0040 r9
    ifp jmp x007
    ifz jmp x007
    ifn call x0050
    jmp x007

    0 0 0 0 0
 
x0030: func
    addi 1 r8 ret
x007:
    ldi 0x4548 r9
    wl r9
    wh r9
    ldi 0x4c4c r9
    wl r9
    wh r9
    ldi 0x204f r9
    wl r9
    wh r9
echo:
    rl r10
    wl r10
    jmp echo

x0040:
    0 0 0 0
    0 0 0 0
    0 0 0 0
    0 0 0 0

x0050: func
    call x0060
    addi 2 r8 ret

    0 0
    0 0 0 0
    0 0 0 0
    0 0 0 0

x0060: func
    ifn addi 2 r8 ret
    ifz addi 2 r8 ret
    ifp addi 2 r8 ret
*/

// compiled
/*
// [0] 1:5: ldi 0x1234 r1
1033
1234
// [2] 2:5: ldi 0xabcd r2
2033
ABCD
// [4] 3:5: ldi 0xffff r3
3033
FFFF
// [6] 4:5: st r2 r1
1273
// [7] 5:5: st r1 r3
3173
// [8] 6:5: ld r2 r6
6253
// [9] 7:5: ld r1 r4
4153
// [10] 8:5: st r3 r1
1373
// [11] 9:5: ld r3 r5
5353
// [12] 10:5: addi 1 r4
4013
// [13] 11:5: addi -1 r4
4F13
// [14] 12:5: add r3 r4
4303
// [15] 13:5: sub r3 r4
4323
// [16] 14:5: or r4 r6
6443
// [17] 15:5: xor r6 r6
6663
// [18] 16:5: and r4 r6
6483
// [19] 17:5: not r4 r6
64A3
// [20] 18:5: cp r1 r6
61C3
// [21] 19:5: shf 1 r6
60E3
// [22] 20:5: shf -1 r6
6FE3
// [23] 21:5: ifz ldi 0x0001 r7
7031
0001
// [25] 22:5: cp r4 r4
44C3
// [26] 23:5: ifn ldi 0x0001 r7
7032
0001
// [28] 24:5: ifp jmp lbl1
004C
// [29] 25:5: jmp lbl1
003F
// [30] 26:5: 0
0000
// [31] 26:7: 0
0000
// [32] 29:5: call x0030
003B
// [33] 30:5: ifp call x0040
0048
// [34] 31:5: ifz call x0040
0049
// [35] 32:5: ifp ldi 0x0040 r9
9030
0040
// [37] 33:5: ifz ldi 0x0040 r9
9031
0040
// [39] 34:5: ifp jmp x007
00AC
// [40] 35:5: ifz jmp x007
009D
// [41] 36:5: ifn call x0050
005A
// [42] 37:5: jmp x007
007F
// [43] 39:5: 0
0000
// [44] 39:7: 0
0000
// [45] 39:9: 0
0000
// [46] 39:11: 0
0000
// [47] 39:13: 0
0000
// [48] 42:5: addi 1 r8 ret
8017
// [49] 44:5: ldi 0x4548 r9
9033
4548
// [51] 45:5: wl r9
9233
// [52] 46:5: wh r9
9A33
// [53] 47:5: ldi 0x4c4c r9
9033
4C4C
// [55] 48:5: wl r9
9233
// [56] 49:5: wh r9
9A33
// [57] 50:5: ldi 0x204f r9
9033
204F
// [59] 51:5: wl r9
9233
// [60] 52:5: wh r9
9A33
// [61] 54:5: rl r10
A633
// [62] 55:5: wl r10
A233
// [63] 56:5: jmp echo
FFEF
// [64] 59:5: 0
0000
// [65] 59:7: 0
0000
// [66] 59:9: 0
0000
// [67] 59:11: 0
0000
// [68] 60:5: 0
0000
// [69] 60:7: 0
0000
// [70] 60:9: 0
0000
// [71] 60:11: 0
0000
// [72] 61:5: 0
0000
// [73] 61:7: 0
0000
// [74] 61:9: 0
0000
// [75] 61:11: 0
0000
// [76] 62:5: 0
0000
// [77] 62:7: 0
0000
// [78] 62:9: 0
0000
// [79] 62:11: 0
0000
// [80] 65:5: call x0060
006B
// [81] 66:5: addi 2 r8 ret
8117
// [82] 68:5: 0
0000
// [83] 68:7: 0
0000
// [84] 69:5: 0
0000
// [85] 69:7: 0
0000
// [86] 69:9: 0
0000
// [87] 69:11: 0
0000
// [88] 70:5: 0
0000
// [89] 70:7: 0
0000
// [90] 70:9: 0
0000
// [91] 70:11: 0
0000
// [92] 71:5: 0
0000
// [93] 71:7: 0
0000
// [94] 71:9: 0
0000
// [95] 71:11: 0
0000
// [96] 74:5: ifn addi 2 r8 ret
8116
// [97] 75:5: ifz addi 2 r8 ret
8115
// [98] 76:5: ifp addi 2 r8 ret
8114

*/

`default_nettype wire
