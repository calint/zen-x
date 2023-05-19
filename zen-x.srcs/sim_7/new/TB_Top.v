`timescale 1ns / 1ps
`default_nettype none

module TB_Top;

localparam clk_tk = 16;
// 100+ns of power-on delay in Verilog simulation due to the under-the-hood assertion of Global Set/Reset signal.
localparam rst_dur = 200;

reg clk = 0;
always #(clk_tk/2) clk = ~clk;

reg rst = 1;

wire [3:0] led;
wire led0_r;
wire led0_g;
wire led0_b;
reg btn = 1;

wire uart_tx;
reg uart_rx = 1;

integer i;

Top top (
    .reset(rst),
    .clk_in(clk),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx),
    .btn(btn),
    .led(led),
    .led0_r(led0_r),
    .led0_g(led0_g),
    .led0_b(led0_b)
);

initial begin
    #rst_dur
    rst = 0;
    // wait until program starts reading uart
    for (i = 0; i < 40; i = i + 1) #clk_tk;    
    $finish;
end

endmodule

`default_nettype wire
