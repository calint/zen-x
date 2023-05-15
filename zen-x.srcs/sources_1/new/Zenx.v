`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Zenx #(
    parameter CLK_FREQ = 66_000_000,
    parameter BAUD_RATE = 9600  
)(
    input wire rst,
    input wire clk,
    input wire btn,
    output wire [3:0] led,
    output wire led0_r,
    output wire led0_g,
    output wire led0_b,
    output wire uart_tx,
    input wire uart_rx
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

// ROM related wiring
wire [15:0] instr; // current instruction from ROM

// uart_rx related (part 1)
reg [REGISTERS_WIDTH-1:0] urx_reg_dat; // content of the destination register
reg [3:0] urx_reg; // destination register
reg urx_regb_sel; // enabled if 'urx_reg' is selected for 'regb'

// instruction break down
wire instr_z = instr[0]; // if enabled execute instruction if z-flag matches 'zn_zf' (also considering instr_n)
wire instr_n = instr[1]; // if enabled execute instruction if n-flag matches 'zn_nf' (also considering instr_z)
// both 'instr_z' and 'instr_n' enabled means execute instruction without considering flags 
wire instr_r = instr[2]; // if enabled returns from current 'call'
wire instr_c = instr[3]; // if enabled 'call'
// note. instr_r && instr_c is 'skp' which jumps to 'pc' + signed immediate 12 bits
wire [3:0] op = instr[7:4]; // operation
wire [3:0] rega = instr[11:8]; // address of 'rega'
wire [3:0] regb =
    is_ldi ? ldi_reg : 
    urx_regb_sel ? urx_reg : // if reading from uart select the destination register
    instr[15:12]; // address of 'regb' or register to be loaded by immediate 16 bits
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
    op == OP_SHF ? {{(REGISTERS_WIDTH-4){rega[3]}},rega} : 
    op == OP_ADDI ? rega[3] ? {{(REGISTERS_WIDTH-4){rega[3]}},rega} : {{(REGISTERS_WIDTH-4){1'b0}},rega} + 1 :
    regs_dat_a; // otherwise regs[a]

// RAM related wiring and registers
reg ram_we; // write enable
wire [REGISTERS_WIDTH-1:0] ram_dat_out; // current data at address 'reg_dat_a'

// Registers related wiring (part 2)
reg regs_we; // write enable
reg [1:0] regs_wd_sel; // selector of data to write to register, 0:alu, 1:ram, 2:instr, 3: urx
wire [REGISTERS_WIDTH-1:0] regs_wd =
    regs_wd_sel == 0 ? alu_result :
    regs_wd_sel == 1 ? ram_dat_out :
    regs_wd_sel == 2 ? instr :
    urx_reg_dat;

// Zn related wiring (part 2)
wire zn_we = is_do_op && ((cs_en && is_cs_op) || (is_alu_op && !is_cs_op)); // update flags if alu op, 'call' or 'return'
wire zn_sel = cs_ret; // if 'zn_we': if 'return' select flags from from Calls otherwise ALU 
wire zn_clr = cs_call; // if 'zn_we': clears the flags if it is a 'call'. has precedence over 'zn_sel'
wire cs_zf, cs_nf, alu_zf, alu_nf; // z- and n-flag wires between Zn, ALU and Calls

/*
// lights
assign led[0] = pc[btn ? 4 : 0];
assign led[1] = pc[btn ? 5 : 1];
assign led[2] = pc[btn ? 6 : 2];
assign led[3] = pc[btn ? 7 : 3];
assign led0_b = 0;
assign led0_g = (pc==61); // pc at finished in hang of rom
assign led0_r = 0;
*/
assign led0_b = 0;
assign led0_r = 0;

// uart_tx related wiring
reg [7:0] utx_dat; // data to send
reg utx_go; // enabled when 'utx_dat' contains data to send and acknowledge 'utx_bsy' low 
wire utx_bsy; // enabled while sending 

// uart_rx related wiring (part 2)
wire [7:0] urx_dat; // last read byte
wire urx_dr; // enabled when data ready
reg urx_go; // enable to start receiving, disable after data received to acknowledge
reg urx_reg_hilo; // read into high or low byte of the register

reg [5:0] stp; // state of instruction execution

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
        regs_we <= 0;
        ram_we <= 0;
        utx_dat <= 0;
        utx_go <= 0;
        urx_reg <= 0;
        urx_regb_sel <= 0;
        urx_reg_hilo <= 0;
        urx_go <= 0;
    end else begin
        `ifdef DBG
            $display("  clk: zenx: %d:%h stp=%0d, doop:%0d, cs_en=%0d, zn=%d%d", pc, instr, stp, is_do_op, cs_en, zn_zf, zn_nf);
        `endif
        if(stp[0]) begin
            // got instruction from rom, execute
            if (is_do_op) begin
                if (cs_call) begin // call
                    pc <= imm12 << 4; // set 'pc'
                    stp <= 1 << 1; 
                end else if (is_cr) begin // jmp
                    pc <= pc + {{(ROM_ADDR_WIDTH-12){imm12[11]}},imm12}; // increment 'pc'
                    stp <= 1 << 1;
                end else begin
                    if (cs_ret) begin // return
                        pc <= cs_pc_out + 1; // get return address from 'Calls'
                    end else begin
                        pc <= pc + 1; // not a return, increment program counter
                    end
                    if (op == OP_LDI && rega != 0) begin // input / output
                        case(rega[2:0]) // operation encoded in 'rega'
                        3'b110: begin // receive blocking
                            urx_reg <= regb; // save 'regb' to be used at write
                            urx_reg_dat <= regs_dat_b; // save current value of 'regb'
                            urx_reg_hilo <= rega[3]; // save if read is to lower or higher 8 bits
                            urx_go <= 1; // signal start read
                            stp <= 1 << 5; // to step 9
                        end
                        3'b010: begin // send blocking
                            utx_dat <= rega[3] ? regs_dat_b[15:8] : regs_dat_b[7:0]; // select the lower or higher bits to send
                            utx_go <= 1; // signal start of transmission
                            stp <= 1 << 4; // to step 7
                        end
                        default: $display("!!! unknown IO op");
                        endcase
                    end else if (is_alu_op) begin
                        regs_we <= 1; // enable write back to register
                        regs_wd_sel <= 0; // select alu result for write to 'regb'
                        stp <= 1 << 1;
                    end else begin
                        case(op)
                        OP_LDI: begin
                            ldi_reg <= regb; // save the register to which the next instruction data will be written
                            stp <= 1 << 2; // to step 2
                        end
                        OP_ST: begin
                            ram_we <= 1; // enable ram write
                            stp <= 1 << 1;
                        end
                        OP_LD: begin
                            regs_we <= 1; // enable register write
                            regs_wd_sel <= 1; // select ram output for write to 'regb'
                            stp <= 1 << 1; // to step 1
                        end
                        default: $display("!!! unknown instruction");
                        endcase
                    end // is_alu_op else
                end // io || is_alu 
            end else begin // !is_do_op, instruction will not execute
                pc <= pc + (!is_cr && (op == OP_LDI) ? 2 : 1); // skip 2 instructions if it is 'ldi'
                stp <= 1 << 1;
            end // is_do_top else
        end else if(stp[1]) begin // wait one cycle for rom and disable controls
            ram_we <= 0; // disable ram write
            regs_we <= 0; // disable register write
            regs_wd_sel <= 0; // select alu result on the write register data
            is_ldi <= 0; // disable flag that instruction is data for 'ldi'
            urx_regb_sel <= 0; // disable signal that 'regb' is 'urx_reg'
            stp <= 1; // done
        end else if(stp[2]) begin // ldi: wait for rom
            is_ldi <= 1; // signal that next instruction is data
            stp <= 1 << 3;
        end else if(stp[3]) begin // ldi: load register
            regs_we <= 1; // enable register write
            regs_wd_sel <= 2; // select register write from rom output
            pc <= pc + 1; // start fetching next instruction
            stp <= 1 << 1;
        end else if(stp[4]) begin // utx: while uart busy wait
            if (!utx_bsy) begin
                utx_go <= 0; // acknowledge that transmission is done
                stp <= 1; // done
            end
        end else if(stp[5]) begin // urx: while data is not ready
            if (urx_dr) begin // if data ready
                if (urx_reg_hilo) begin
                    urx_reg_dat[15:8] <= urx_dat; // write the high byte
                end else begin
                    urx_reg_dat[7:0] <= urx_dat; // write the low byte
                end
                urx_go <= 0; // acknowledge the ready data has been read
                regs_we <= 1; // enable register write
                regs_wd_sel <= 3; // select data to write to register from 'urx_reg_dat'
                urx_regb_sel <= 1; // signal that 'regb' is 'urx_reg'
                stp <= 1 << 1;
            end
        end // stp[x]
    end // else rst
end

BlockROM rom ( // 32K x 16b
    .clka(clk),
    .addra(pc),
    .douta(instr)
);

Calls #(
    CALLS_ADDR_WIDTH,
    ROM_ADDR_WIDTH
) cs (
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

Registers #(
    REGISTERS_ADDR_WIDTH,
    REGISTERS_WIDTH
) regs ( // 16 x 16b
    .clk(clk),
    .ra1(rega), // register address 1
    .ra2(regb), // register address 2
    .wd(regs_wd), // data to write to register 'ra2' when 'we' is enabled
    .we(regs_we), // enables write 'wd' to address 'ra2'
    .rd1(regs_dat_a), // register data 1
    .rd2(regs_dat_b) // register data 2
);

ALU #(
    REGISTERS_WIDTH
) alu (
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

BlockRAM ram ( // 64K x 16b
    .clka(clk),
    .wea(ram_we),
    .addra(regs_dat_a),
    .dina(regs_dat_b),
    .douta(ram_dat_out)
);

UartTx #(
    CLK_FREQ,
    BAUD_RATE
) utx (
    .rst(rst),
    .clk(clk),
    .data(utx_dat),
    .go(utx_go),
    .tx(uart_tx),
    .bsy(utx_bsy)
);

UartRx #(
    CLK_FREQ,
    BAUD_RATE
) urx (
    .rst(rst),
    .clk(clk),
    .rx(uart_rx),
    .data(urx_dat),
    .dr(urx_dr),
    .go(urx_go),
    .led(led),
    .led_g(led0_g)
);

endmodule

`default_nettype wire