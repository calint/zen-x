`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Calls #(parameter ADDR_WIDTH = 4, parameter ROM_ADDR_WIDTH = 16) (
    input wire rst,
    input wire clk,
    input wire [ROM_ADDR_WIDTH-1:0] pc_in, // current program counter
    input wire zf_in, // current zero flag
    input wire nf_in, // current negative flag
    input wire push, // enabled when it is a 'call'
    input wire pop, // enabled when instruction is also 'return'
    input wire en, // enables push or pop
    output reg [ROM_ADDR_WIDTH-1:0] pc_out, // top of stack program counter
    output reg zf_out, // top of stack zero flag
    output reg nf_out // top of stack negative flag
);

reg [ADDR_WIDTH-1:0] idx;
reg [ROM_ADDR_WIDTH+1:0] mem [0:2**ADDR_WIDTH-1]; // {zf, nf, addr}
reg [ROM_ADDR_WIDTH-1:0] pc_out_nxt;
reg zf_out_nxt;
reg nf_out_nxt;

integer i;
initial begin
    for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
        mem[i] = {(ROM_ADDR_WIDTH+2){1'b0}}; // {zf, nf, addr}
    end
end

always @(negedge clk) begin
//    `ifdef DBG
//        $display(" ~clk: Calls: pc=%0d, en=%0d, push=%0d, pop=%0d", pc_in, en, push, pop);
//    `endif
    pc_out <= pc_out_nxt;
    zf_out <= zf_out_nxt;
    nf_out <= nf_out_nxt;
end

always @(posedge clk) begin
    `ifdef DBG
        $display("  clk: Calls: pc=%0d, en=%0d, push=%0d, pop=%0d", pc_in, en, push, pop);
    `endif

    if (rst) begin
        idx <= {ADDR_WIDTH{1'b1}};
    end else begin
        if (en) begin
            if (push) begin
                idx = idx + 1;
                mem[idx] <= {zf_in, nf_in, pc_in};
                zf_out_nxt <= zf_in;
                nf_out_nxt <= nf_in;
                pc_out_nxt <= pc_in;
            end else if (pop) begin
                idx = idx - 1;
                zf_out_nxt <= mem[idx][ROM_ADDR_WIDTH+1];
                nf_out_nxt <= mem[idx][ROM_ADDR_WIDTH];
                pc_out_nxt <= mem[idx][ROM_ADDR_WIDTH-1:0];
            end
        end
    end
end

endmodule

`default_nettype wire