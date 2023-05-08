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
    .reset(rst),
    .clk_in(clk),
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
    
    // ram write
    #clk_tk;
    #clk_tk;
    
    // rom read
    #clk_tk;
    #clk_tk;
    
    // ram write
    #clk_tk;
    #clk_tk;

    $finish;
end

endmodule

`default_nettype wire
