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
    output reg [2:0] alu_op
);

reg [2:0] stp;
reg [14:0] addr;

always @(negedge clk) begin
    if (rst) begin
        stp <= 0;
        addr <= 0;
    end else begin
        case(stp)
        3'd0: begin
            ram_en <= 0;
            ram_we <= 0;
            rom_en <= 1;
            rom_addr <= addr;
            stp <= 1;
        end
        3'd1: begin
            stp <= 2;
        end
        3'd2: begin
            rom_en <= 0;
            ram_en <= 1;
            ram_we <= 1;
            ram_addr <= addr;
            ram_dat_in <= rom_dat;
            stp <= 3;
        end
        3'd3: begin
            stp <= 0;
        end        
        endcase
    end
end

endmodule

`default_nettype wire