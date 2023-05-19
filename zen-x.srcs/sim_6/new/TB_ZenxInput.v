`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module TB_ZenxInput;

localparam ROM_FILE = "/home/c/w/zen-x/zen-x.srcs/sim_6/new/TB_ZenxInput.hex";
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
    .ROM_FILE(ROM_FILE),
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
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
    // wait until program starts reading uart
    for (i = 0; i < 40; i = i + 1) #clk_tk;
    
    // receive 'A' 0x41 0b0100_0001
    uart_rx = 1; // idle
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0; // start bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    
    uart_rx = 0;
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
    if (zx.urx.data_reg==8'h41) $display("case 1 passed");
    else $display("case 1 FAILED. expected 0x41, got %0h", zx.urx.data_reg);

    // wait for echo and then read again
    for (i = 0; i < 20 * UART_TICKS_PER_BIT; i = i + 1) begin
        #clk_tk;
    end
    
    // receive '\r' 0x0d 0b0000_1101
    uart_rx = 1; // idle
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0; // start bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // first bit (lowest)    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
   
    uart_rx = 0;
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // stop bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // idle
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    if (zx.urx.data_reg==8'h0a) $display("case 2 passed");
    else $display("case 2 FAILED. expected 0x0a, got %0h", zx.urx.data_reg);

    // wait ...
    for (i = 0; i < 1000; i = i + 1) #clk_tk;

    $finish;
end

endmodule

`default_nettype wire
