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
reg [14:0] pc;

// OP_LOADI related registers
reg is_loadi; // enabled if data from current instruction is written to register 'loadi_reg'
reg do_loadi; // enabled if 'loadi' was set during a 'is_do_op' operation, if disabled ignore the instruction
reg [3:0] loadi_reg; // register to write when doing 'loadi'

// ROM related wiring
wire [15:0] instr = rom_dat; // current instruction from ROM

// instruction break down
wire instr_z = instr[0]; // if enabled execute instruction if z-flag matches 'zn_zf' (also considering instr_n)
wire instr_n = instr[1]; // if enabled execute instruction if n-flag matches 'zn_nf' (also considering instr_z)
// both 'instr_z' and 'instr_n' enabled means execute instruction without considering flags 
wire instr_x = instr[2]; // if enabled steps an iteration in current loop
wire instr_r = instr[3]; // if enabled returns from current 'call', if 'instr_x' and loop not finished then ignored
wire instr_c = instr[4]; // if enabled 'call'
// note. instr_r && instr_c is illegal and instead enables another page of operations that can't 'return' during same operation
wire [3:0] op = instr[7:5]; // operation
wire [3:0] rega = instr[11:8]; // address of 'rega'
wire [3:0] regb = is_loadi ? loadi_reg : instr[15:12]; // address of 'regb'
wire [10:0] imm12 = instr[15:4];

// Zn related wiring (part 1)
wire zn_zf, zn_nf; // zero- and negative flags wired to Zn outputs

// enabled if instruction will execute
wire is_do_op = !is_loadi && ((instr_z && instr_n) || (zn_zf==instr_z && zn_nf==instr_n));


always @(negedge clk) begin
    if (rst) begin
        stp <= 1;
        pc <= 0;
    end else begin
        if (stp[0]) begin
            // read next instruction from rom
            ram_en <= 0;
            ram_we <= 0;
            rom_en <= 1;
            rom_addr <= pc;
            stp <= stp << 1;
        end else if(stp[1]) begin
            // wait for rom
            stp <= stp << 1;
        end else if(stp[2]) begin
            // execute instruction
            rom_en <= 0;
            ram_en <= 1;
            ram_we <= 1;
            ram_addr <= pc;
            ram_dat_in <= rom_dat;
            stp <= stp << 1;
        end else if(stp[3]) begin
            // wait for ram
            pc <= pc + 1;
            stp <= 1;
        end        
    end
end

endmodule

`default_nettype wire