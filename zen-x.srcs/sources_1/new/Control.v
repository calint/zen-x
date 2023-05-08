`timescale 1ns / 1ps
`default_nettype none

module Control(
    input wire rst,
    input wire clk,
    input wire [15:0] rom_dat,
    input wire [15:0] ram_dat,
    input wire [15:0] alu_result,
    input wire alu_zf,
    input wire alu_nf,
    output reg rom_en,
    output reg [14:0] rom_addr,
    output reg ram_en,
    output reg ram_we,
    output reg [15:0] ram_addr,
    output reg [15:0] ram_dat_in,
    output reg [2:0] alu_op,
    output reg [15:0] debug
);

reg [3:0] stp;
reg [14:0] addr;

always @(negedge clk) begin
    if (rst) begin
        stp <= 1;
        addr <= 0;
    end else begin
        if (stp[0]) begin
            ram_en <= 0;
            ram_we <= 0;
            rom_en <= 1;
            rom_addr <= addr;
            stp <= stp << 1;
        end else if(stp[1]) begin
            stp <= stp << 1;
        end else if(stp[2]) begin
            rom_en <= 0;
            ram_en <= 1;
            ram_we <= 1;
            ram_addr <= addr;
            ram_dat_in <= rom_dat;
            stp <= stp << 1;
        end else if(stp[3]) begin
            addr <= addr + 1;
            stp <= 1;
        end        
    end
end

endmodule

`default_nettype wire