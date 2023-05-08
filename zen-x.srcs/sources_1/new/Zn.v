`timescale 1ns / 1ps
`default_nettype none

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
    
always @(posedge clk) begin
    `ifdef DBG
        $display("  clk: Zn");
    `endif

    if (rst) begin
        zf <= 0;
        nf <= 0;
    end else begin
        if (we) begin
            if (clr) begin
                zf <= 0;
                nf <= 0;
            end else begin
                zf <= sel ? cs_zf : alu_zf;
                nf <= sel ? cs_nf : alu_nf;
            end
        end
    end
end    
    
endmodule

`default_nettype wire