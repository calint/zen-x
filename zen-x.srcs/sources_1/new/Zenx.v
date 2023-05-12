`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Zenx (
    input wire rst,
    input wire clk,
    input wire btn,
    output wire [3:0] led,
    output wire led0_r,
    output wire led0_g,
    output wire led0_b
);

localparam ROM_ADDR_WIDTH = 15; // 2**16 32K instructions
localparam RAM_ADDR_WIDTH = 16; // 2**16 data addresses
localparam CALLS_ADDR_WIDTH = 6; // 2**6 stack
localparam REGISTERS_ADDR_WIDTH = 4; // 2**4 registers (not changable since register address encoded in instruction using 4 bits) 
localparam REGISTERS_WIDTH = 16; // 16 bit

localparam OP_ADDI = 4'b0001; // add immediate signed 4 bits value
localparam OP_LDI  = 4'b0011; // load immediate 16 bits from next instruction
localparam OP_LD   = 4'b0101; // load
localparam OP_ST   = 4'b0111; // store
localparam OP_SHF  = 4'b1110; // shift

localparam ALU_ADD = 3'b000; // addition
localparam ALU_SUB = 3'b001; // substraction
localparam ALU_OR  = 3'b010; // bitwise or
localparam ALU_XOR = 3'b011; // bitwise xor
localparam ALU_AND = 3'b100; // bitwise and
localparam ALU_NOT = 3'b101; // bitwise not
localparam ALU_CP  = 3'b110; // copy
localparam ALU_SHF = 3'b111; // shift immediate signed 4 bits value

reg [ROM_ADDR_WIDTH-1:0] pc; // program counter

// OP_LDI related registers
reg is_ldi; // enabled if current instruction is data for 'ldi'
reg [3:0] ldi_reg; // register to write when 'ldi'
reg ldi_do; // used for coordination in instruction execution steps

// ROM related wiring
wire [15:0] instr; // current instruction from ROM

// instruction break down
wire instr_z = instr[0]; // if enabled execute instruction if z-flag matches 'zn_zf' (also considering instr_n)
wire instr_n = instr[1]; // if enabled execute instruction if n-flag matches 'zn_nf' (also considering instr_z)
// both 'instr_z' and 'instr_n' enabled means execute instruction without considering flags 
wire instr_r = instr[2]; // if enabled returns from current 'call'
wire instr_c = instr[3]; // if enabled 'call'
// note. instr_r && instr_c is 'skp' which jumps to 'pc' + signed immediate 12 bits
wire [3:0] op = instr[7:4]; // operation
wire [3:0] rega = instr[11:8]; // address of 'rega'
wire [3:0] regb = is_ldi ? ldi_reg : instr[15:12]; // address of 'regb' or register to be loaded by immediate 16 bits
wire [11:0] imm12 = instr[15:4];

// Zn related wiring (part 1)
wire zn_zf, zn_nf; // zero- and negative flags wired to Zn outputs

// enabled if instruction will execute
wire is_do_op = !is_ldi && ((instr_z && instr_n) || (zn_zf == instr_z && zn_nf == instr_n));

// Calls related wiring (part 1)
wire is_cr = instr_c && instr_r; // enabled if c && r which means it is 'skp'
wire is_cs_op = is_do_op && (instr_c ^ instr_r); // enabled if instruction operates on 'Calls'
wire cs_call = is_cs_op && instr_c; // enabled if instruction is 'call'
wire cs_ret = is_cs_op && instr_r; // enabled if 'return'
wire [ROM_ADDR_WIDTH-1:0] cs_pc_out; // 'pc' before the 'call'
wire cs_zf_out; // zero-flag before the 'call'
wire cs_nf_out; // negative-flag before the 'call'
reg cs_en; // used to coordinate call / ret and Zn

// Registers related wiring (part 1)
wire [REGISTERS_WIDTH-1:0] regs_dat_a; // regs[a]
wire [REGISTERS_WIDTH-1:0] regs_dat_b; // regs[b]

// ALU related wiring
wire [REGISTERS_WIDTH-1:0] alu_result;
wire is_alu_op = !is_ldi && !is_cr && !cs_call && (!op[0] || op == OP_ADDI);
wire [2:0] alu_op = 
    op == OP_ADDI ? ALU_ADD : // 'addi' is add with signed immediate value 'rega'
    op[3:1]; // same as upper 3 bits of op
wire [REGISTERS_WIDTH-1:0] alu_operand_a =
    (op == OP_SHF || op == OP_ADDI) ? {{(REGISTERS_WIDTH-4){rega[3]}},rega} : // sign extend 4 bits to register width
    regs_dat_a; // otherwise regs[a]

// RAM related wiring and registers
reg ram_we; // write enable
wire [REGISTERS_WIDTH-1:0] ram_dat_out; // current data at address 'reg_dat_a'

// Registers related wiring (part 2)
reg regs_we; // write enable
reg [1:0] regs_wd_sel; // selector of data to write to register, 0:alu, 1:ram, 2:instr
wire [REGISTERS_WIDTH-1:0] regs_wd =
    regs_wd_sel == 0 ? alu_result :
    regs_wd_sel == 1 ? ram_dat_out :
    instr;

// Zn related wiring (part 2)
wire zn_we = is_do_op && ((cs_en && is_cs_op) || (is_alu_op && !is_cs_op)); // update flags if alu op, 'call' or 'return'
wire zn_sel = cs_ret; // if 'zn_we': if 'return' select flags from from Calls otherwise ALU 
wire zn_clr = cs_call; // if 'zn_we': clears the flags if it is a 'call'. has precedence over 'zn_sel'
wire cs_zf, cs_nf, alu_zf, alu_nf; // z- and n-flag wires between Zn, ALU and Calls

reg [7:0] stp; // state of instruction execution

// debugging
assign led[0] = pc[btn ? 4 : 0];
assign led[1] = pc[btn ? 5 : 1];
assign led[2] = pc[btn ? 6 : 2];
assign led[3] = pc[btn ? 7 : 3];
assign led0_b = 0;
assign led0_g = (pc==50); // pc at finished in hang of rom
assign led0_r = 0;

/*
always @* begin
    if (is_jmp) begin
        // doesn't work because of the 'spurios' spike while combo is evaluating
        pc = pc + {{(4){imm12[11]}}, imm12};
    end
end
*/

always @(negedge clk) begin
    if (rst) begin
        cs_en <= 0;
    end else begin
        if (is_cs_op) begin // this will be called twice while the instruction executes
            cs_en <= ~cs_en; // coordination to avoid racing
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        stp <= 1;
        pc <= 0;
        regs_wd_sel = 0;
        is_ldi <= 0;
        ldi_do <= 0;
        regs_we <= 0;
        ram_we <= 0;
    end else begin
        `ifdef DBG
            $display("  clk: zenx: %d:%h stp=%0d, doop:%0d, cs_en=%0d", pc, instr, stp, is_do_op, cs_en);
        `endif
        if(stp[0]) begin
            // got instruction from rom, execute
            if (cs_call) begin // call
                pc <= imm12 << 4;
                stp <= 1 << 6;
            end else if (is_cr) begin // skp
                pc <= pc + (is_do_op ? {{(ROM_ADDR_WIDTH-12){imm12[11]}},imm12} : 1);
                stp <= 1 << 6;
            end else begin
                if (cs_ret) begin // return
                    pc <= cs_pc_out + 1; // get return address from 'Calls'
                end else begin
                    pc <= pc + 1; // start fetching next instruction
                end
                if (is_alu_op) begin
                    regs_we <= is_do_op; // enable write back to register if instruction should execute
                    regs_wd_sel <= 0; // select alu result for write to 'regb'
                    stp <= 1 << 5;
                end else begin
                    case(op)
                    OP_LDI: begin
                        ldi_reg <= regb;
                        ldi_do <= is_do_op;
                        stp <= stp << 2;
                    end
                    OP_ST: begin
                        ram_we <= is_do_op;
                        stp <= stp << 1;
                    end
                    OP_LD: begin
                        regs_we <= is_do_op;
                        regs_wd_sel <= 1; // select ram output for write to 'regb'
                        stp <= stp << 1;
                    end
                    default: $display("!!! unknown instruction");
                    endcase
                end // is_alu_op
            end // is_jmp
        end else if(stp[1]) begin // ld, st: wait one cycle for ram op to finish
            // ? separate this into 2 different steps which disables 'we' for the relevant component
            ram_we <= 0; // if it is 'st'
            regs_we <= 0; // if it is 'ld'
            stp <= 1;
        end else if(stp[2]) begin // ldi: wait for rom
            is_ldi <= 1; // signal that next instruction is data
            stp <= stp << 1;
        end else if(stp[3]) begin // ldi: load register
            regs_we <= ldi_do; // enable register write if 'ldi' is executed
            regs_wd_sel <= ldi_do ? 2 : 0; // select register write from rom output
            pc <= pc + 1; // start fetching next instruction
            stp <= stp << 1;
        end else if(stp[4]) begin // ldi: wait for rom to get next instruction
            regs_we <= 0;
            ldi_do <= 0;
            is_ldi <= 0;
            stp <= 1;
        end else if(stp[5]) begin // alu: wait one cycle for rom to get next instruction
            regs_we <= 0;
            stp <= 1;
        end else if(stp[6]) begin // call, skp: wait one cycle for rom to get next instruction
            stp <= 1;
        end // stp[x]
    end // else rst
end

BlockROM rom ( // 32K x 16b
    .clka(clk),
    .addra(pc),
    .douta(instr)
);

Calls #(CALLS_ADDR_WIDTH, ROM_ADDR_WIDTH) cs (
    .rst(rst),
    .clk(clk),
    .pc_in(pc), // current program counter
    .zf_in(zn_zf), // current zero flag
    .nf_in(zn_nf), // current negative flag
    .call(cs_call), // enabled when it is a 'call'
    .ret(cs_ret), // enabled when instruction is also 'return'
    .en(cs_en), // enables 'push' or 'pop'
    .pc_out(cs_pc_out), // top of stack program counter
    .zf_out(cs_zf), // top of stack zero flag
    .nf_out(cs_nf) // top of stack negative flag
);

Registers #(REGISTERS_ADDR_WIDTH, REGISTERS_WIDTH) regs ( // 16 x 16b
    .clk(clk),
    .ra1(rega), // register address 1
    .ra2(regb), // register address 2
    .wd(regs_wd), // data to write to register 'ra2' when 'we' is enabled
    .we(regs_we), // enables write 'wd' to address 'ra2'
    .rd1(regs_dat_a), // register data 1
    .rd2(regs_dat_b) // register data 2
);

ALU #(REGISTERS_WIDTH) alu (
    .op(alu_op),
    .a(alu_operand_a),
    .b(regs_dat_b),
    .result(alu_result),
    .zf(alu_zf),
    .nf(alu_nf)
);

Zn zn (
    .rst(rst),
    .clk(clk),
    .cs_zf(cs_zf),
    .cs_nf(cs_nf),
    .alu_zf(alu_zf),
    .alu_nf(alu_nf),
    .we(zn_we), // depending on 'sel' copy 'Calls' or 'ALU' zn flags
    .sel(zn_sel), // selector when 'we', enabled cs_*, disabled alu_* 
    .clr(zn_clr), // selector when 'we', clears the flags, has precedence over 'sel'
    .zf(zn_zf),
    .nf(zn_nf)
);

BlockRAM ram( // 64K x 16b
    .clka(clk),
    .wea(ram_we),
    .addra(regs_dat_a),
    .dina(regs_dat_b),
    .douta(ram_dat_out)
);

endmodule

`default_nettype wire