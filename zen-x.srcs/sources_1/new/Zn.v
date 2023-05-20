`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Zn(
    input wire rst,
    input wire clk,
    input wire cs_zf,
    input wire cs_nf,
    input wire alu_zf,
    input wire alu_nf,
    input wire we, // depending on 'sel' copy 'CallStack' or 'ALU' zn flags
    input wire sel, // selector when 'we', enabled cs_*, disabled alu_* 
    input wire clr, // selector when 'we', clears the flags, has precedence over 'sel'
    output reg zf,
    output reg nf
);

reg zf_nxt;
reg nf_nxt;

always @(negedge clk) begin
    zf <= zf_nxt;
    nf <= nf_nxt;
end
    
always @(posedge clk) begin
    `ifdef DBG
        $display("%0t: clk+: Zn (zf,nf)=(%0d,%0d)", $time, zf, nf);
    `endif

    if (rst) begin
        zf_nxt <= 0;
        nf_nxt <= 0;
    end else begin
        if (we) begin
            if (clr) begin
                zf_nxt <= 0;
                nf_nxt <= 0;
            end else begin
                zf_nxt <= sel ? cs_zf : alu_zf;
                nf_nxt <= sel ? cs_nf : alu_nf;
            end
        end
    end
end    
    
endmodule

`undef DBG
`default_nettype wire