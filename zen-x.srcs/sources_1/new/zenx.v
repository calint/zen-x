`timescale 1ns / 1ps
`default_nettype none
`define DBG

module zenx(
    input wire rst,
    input wire clk,
    output wire [3:0] led,
    output wire [15:0] debug
);

localparam ROM_ADDR_WIDTH = 15; // 2**15 instructions
localparam RAM_ADDR_WIDTH = 16; // 2**16 data addresses
localparam REGISTERS_ADDR_WIDTH = 4; // 2**4 registers
localparam CALLS_ADDR_WIDTH = 4; // 2**4 stack
localparam REGISTERS_WIDTH = 16; // 16 bit

localparam OP_ADDI = 4'b0001;
localparam OP_LDI  = 4'b1001;
localparam OP_ST   = 4'b1101;
localparam OP_LD   = 4'b0101;

reg rom_en;

reg ram_en;
reg ram_we;
wire [15:0] ram_dat_out;

reg [2:0] alu_op;
reg [15:0] alu_a = 0;
reg [15:0] alu_b = 0;
wire [15:0] alu_result;
wire alu_zf;
wire alu_nf;

// Zn wires to CallStack and ALU
wire cs_zf;
wire cs_nf;
wire zn_we;
wire zn_sel; 
wire zn_clr;

// Calls wires
wire cs_push;
wire cs_pop;
wire [14:0] cs_pc_out;
wire cs_zf_out;
wire cs_nf_out;

assign led[0] = instr[7:4];

reg [14:0] pc;

// OP_LDI related registers
reg is_ldi; // enabled if data from current instruction is written to register 'loadi_reg'
reg do_ldi; // enabled if 'loadi' was set during a 'is_do_op' operation, if disabled ignore the instruction
reg [3:0] ldi_reg; // register to write when doing 'loadi'

// ROM related wiring
wire [15:0] instr; // current instruction from ROM

// instruction break down
wire instr_z = instr[0]; // if enabled execute instruction if z-flag matches 'zn_zf' (also considering instr_n)
wire instr_n = instr[1]; // if enabled execute instruction if n-flag matches 'zn_nf' (also considering instr_z)
// both 'instr_z' and 'instr_n' enabled means execute instruction without considering flags 
wire instr_x = instr[2]; // if enabled steps an iteration in current loop
wire instr_r = instr[3]; // if enabled returns from current 'call', if 'instr_x' and loop not finished then ignored
wire instr_c = instr[4]; // if enabled 'call'
// note. instr_r && instr_c is illegal and instead enables another page of operations that can't 'return' during same operation
wire [3:0] op = instr[7:4]; // operation
wire [3:0] rega = instr[11:8]; // address of 'rega'
wire [3:0] regb = is_ldi ? ldi_reg : instr[15:12]; // address of 'regb'
wire [10:0] imm12 = instr[15:4];

// Zn related wiring (part 1)
wire zn_zf, zn_nf; // zero- and negative flags wired to Zn outputs

// enabled if instruction will execute
wire is_do_op = !is_ldi && ((instr_z && instr_n) || (zn_zf==instr_z && zn_nf==instr_n));

// CallStack related wiring
wire is_cr = instr_c && instr_r; // enabled if illegal c && r op => enables 8 other instructions that can't piggy back 'return'
wire is_cs_op = is_do_op && !is_cr && (instr_c ^ instr_r); // enabled if instruction operates on CallStack
wire cs_push = is_cs_op && instr_c; // enabled if instruction is 'call'
wire cs_pop = is_cs_op && instr_r; // enabled if 'return', disabled if also 'next' and loop not finished
wire [14:0] cs_pc_out; // address to 'pc' if 'return'


reg regs_we; // registers write enabled
reg [1:0] regs_wd_sel; // selector of data to write to register, 0:alu, 1:ram, 2:instr
wire [15:0] regs_rd1; // regs[a]
wire [15:0] regs_rd2; // regs[b]
wire [15:0] regs_wd =
    regs_wd_sel == 0 ? alu_result :
    regs_wd_sel == 1 ? ram_dat_out :
    instr;

// ALU related wiring
wire is_alu_op = !is_ldi && !is_cr && !cs_push && (op[4] || op == OP_ADDI);
wire [2:0] alu_op = 
    op == OP_ADDI ? ALU_ADD : // 'addi' is add with signed immediate value 'rega'
    op[7:5]; // same as op
wire [15:0] alu_operand_a = 
    op == OP_ADDI ? {{(12){rega[3]}}, rega} : // 'addi' is add with signed immediate value 'rega'
    regs_rd1; // otherwise regs[rega]

// Zn related wiring (part 2)
wire zn_we = is_do_op && (is_alu_op || cs_pop || cs_push); // update flags if alu op, 'call' or 'return'
wire zn_sel = cs_pop; // if 'zn_we': if 'return' select flags from from CallStack otherwise ALU 
wire zn_clr = cs_push; // if 'zn_we': clears the flags if it is a 'call'. has precedence over 'zn_sel'
wire cs_zf, cs_nf, alu_zf, alu_nf; // z- and n-flag wires between Zn, ALU and CallStack

// RAM related
reg [15:0] ram_dat_to_write;

reg [8:0] stp;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        stp <= 1;
        pc <= 0;
        regs_wd_sel = 0;
        is_ldi <= 0;
        regs_we <= 0;
        ram_we <= 0;
        ram_en <= 0;
        rom_en <= 1; // start reading first instruction
    end else begin
        `ifdef DBG
            $display("  clk: zenx: %d:%h stp:%0d, doop:%0d", pc, instr, stp, is_do_op);
        `endif
        
        if(stp[0]) begin
            // got instruction from rom
            // execute
            case(op)
            OP_LDI: begin
                is_ldi <= 1;
                regs_we <= 0;
                ram_we <= 0;
                ram_en <= 0;
                ldi_reg <= regb;
                pc <= pc + 1; // start fetching next instruction
                stp <= stp << 2;
            end
            OP_ST: begin
                is_ldi <= 0;
                regs_we <= 0;
                ram_en <= 1;
                ram_we <= 1;
                pc <= pc + 1; // start fetching next instruction
                stp <= stp << 1;
            end
            OP_LD: begin
                regs_we <= 1;
                ram_en <= 1;
                ram_we <= 0;
                regs_wd_sel <= 1; // select ram output for write to 'regb'
                pc <= pc + 1; // start fetching next instruction
                stp <= stp << 1;
            end
            default: $display("!!! unknown instruction");
            endcase
        end else if(stp[1]) begin // ld,st: wait one cycle for ram op to finish
            ram_we <= 0;
            regs_we <= 0;
            stp <= 1;
        end else if(stp[2]) begin // ldi: wait for rom
            stp = stp << 1;
        end else if(stp[3]) begin // ldi: load register
            regs_we <= 1; // write rom output to register
            regs_wd_sel <= 2; // select register to write from rom output
            pc <= pc + 1; // start fetching next instruction
            stp <= stp << 1;
        end else if(stp[4]) begin // ldi: wait for rom to get next instruction
            regs_we <= 0;
            is_ldi <= 0;
            stp <= 1;
        end      
    end
end

BlockROM brom( // 32K x 16b
    .clka(clk),
    .ena(rom_en),
    .addra(pc),
    .douta(instr)
);

Calls cs(
    .rst(rst),
    .clk(clk),
    .pc_in(pc), // current program counter
    .zf_in(zn_zf), // current zero flag
    .nf_in(zn_nf), // current negative flag
    .push(cs_push),
    .pop(cs_pop),
    .pc_out(cs_pc_out), // top of stack program counter
    .zf_out(cs_zf), // top of stack zero flag
    .nf_out(cs_nf) // top of stack negative flag
);

Registers regs( // 16 x 16b
    .clk(clk),
    .ra1(rega), // register address 1
    .ra2(regb), // register address 2
    .we(regs_we), // write 'wd' to address 'ra2'
    .wd(regs_wd), // data to write to register 'ra2' when 'we' is enabled
    .rd1(regs_rd1), // register data 1
    .rd2(regs_rd2) // register data 2
);

ALU alu(
    .op(alu_op),
    .a(alu_a),
    .b(alu_b),
    .result(alu_result),
    .zf(alu_zf),
    .nf(alu_nf)
);

Zn zn(
    .rst(rst),
    .clk(clk),
    .cs_zf(cs_zf),
    .cs_nf(cs_nf),
    .alu_zf(alu_zf),
    .alu_nf(alu_nf),
    .we(zn_we), // depending on 'sel' copy 'CallStack' or 'ALU' zn flags
    .sel(zn_sel), // selector when 'we', enabled cs_*, disabled alu_* 
    .clr(zn_clr), // selector when 'we', clears the flags, has precedence over 'sel'
    .zf(zn_zf),
    .nf(zn_nf)
);

BlockRAM bram( // 64K x 16b
    .clka(clk),
    .ena(ram_en),
    .wea(ram_we),
    .addra(regs_rd1),
//    .dina(ram_dat_to_write), // regs_rd2
    .dina(regs_rd2),
    .douta(ram_dat_out)
);

endmodule

`default_nettype wire