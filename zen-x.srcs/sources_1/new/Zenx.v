`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Zenx #(
    parameter ROM_FILE = "ROM.hex",
    parameter CLK_FREQ = 66_000_000,
    parameter BAUD_RATE = 9600
)(
    input wire rst,
    input wire clk,
    input wire btn,
    output reg [3:0] led,
    output wire led0_r,
    output wire led0_g,
    output wire led0_b,
    output wire uart_tx,
    input wire uart_rx
);

localparam ROM_ADDR_WIDTH = 16; // 2**16 64K instructions
localparam RAM_ADDR_WIDTH = 16; // 2**16 64K data addresses
localparam CALLS_ADDR_WIDTH = 6; // 2**6 64 stack
localparam REGISTERS_ADDR_WIDTH = 4; // 2**4 16 registers (not changable since register address encoded in instruction using 4 bits) 
localparam REGISTERS_WIDTH = 16; // 16 bit

localparam OP_ADDI = 4'b0001; // add immediate signed 4 bits value where imm4>=0?++imm4:-imm4
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
localparam ALU_SHF = 3'b111; // shift immediate signed 4 bits value where imm4>=0?++imm4:-imm4

reg [ROM_ADDR_WIDTH-1:0] pc; // program counter

// OP_LDI related registers
reg is_ldi; // enabled if current instruction is data to load
reg [3:0] ldi_reg; // register to write data to
reg ldi_is_ret; // enabled if 'ldi' operation had 'ret' (used later in the instruction cycle to set 'ldi_ret')
reg ldi_ret; // enabled by 'ldi_ret_do' at the end of the 'ldi' cycle to trigger 'Calls' to return from current 'call'

// ROM related wiring
wire [15:0] instr; // current instruction from ROM

// UartRx related (part 1)
reg [REGISTERS_WIDTH-1:0] urx_reg_dat; // content of the destination register, the received byte is or'ed into this register
reg [3:0] urx_reg; // destination register of data from receive
reg urx_regb_sel; // enabled if 'urx_reg' is selected for 'regb'

// instruction break down
wire instr_z = instr[0]; // if enabled execute instruction if z-flag matches 'zn_zf' (also considering instr_n)
wire instr_n = instr[1]; // if enabled execute instruction if n-flag matches 'zn_nf' (also considering instr_z)
// both 'instr_z' and 'instr_n' enabled means execute instruction without considering flags 
wire instr_r = instr[2]; // if enabled returns from current 'call'
wire instr_c = instr[3]; // if enabled 'call'
wire is_jmp = instr_c && instr_r; // enabled if 'jmp' instruction
wire [3:0] op = instr[7:4]; // operation
wire [3:0] rega = instr[11:8]; // address of 'rega'
wire [3:0] regb =
    is_ldi ? ldi_reg : // if loading instruction data into register
    urx_regb_sel ? urx_reg : // if reading from uart
    instr[15:12]; // address of 'regb'
wire [11:0] imm12 = instr[15:4]; // 12 bit number if it is 'call' or 'jmp'

// Zn related wiring (part 1)
wire zn_zf, zn_nf; // zero- and negative flags wired to Zn outputs

// enabled if instruction will execute
wire is_do_op = !is_ldi && ((instr_z && instr_n) || (zn_zf == instr_z && zn_nf == instr_n));

// Calls related wiring (part 1)
wire is_cs_op = ldi_ret || (is_do_op && (instr_c ^ instr_r)); // enabled if instruction operates on 'Calls'
wire cs_call = !ldi_ret && is_cs_op && instr_c; // enabled if instruction is 'call'
wire is_ret = is_cs_op && instr_r; // enabled if current instruction has 'ret'
wire cs_ret = ldi_ret || (is_ret && !(op == OP_LDI && rega == 0)); // enabled if 'Calls' should do 'ret'
wire [ROM_ADDR_WIDTH-1:0] cs_pc_out; // 'pc' before the 'call'
wire cs_zf_out; // zero-flag before the 'call'
wire cs_nf_out; // negative-flag before the 'call'
reg cs_en; // used to coordinate call / ret and Zn

// Registers related wiring (part 1)
wire [REGISTERS_WIDTH-1:0] regs_dat_a; // regs[a]
wire [REGISTERS_WIDTH-1:0] regs_dat_b; // regs[b]

// ALU related wiring
wire [REGISTERS_WIDTH-1:0] alu_result;
wire is_alu_op = !is_ldi && !is_jmp && !cs_call && (!op[0] || op == OP_ADDI);
wire [2:0] alu_op = 
    op == OP_ADDI ? ALU_ADD : // 'addi' is add with signed immediate value 'rega'
    op[3:1]; // same as upper 3 bits of op
wire [REGISTERS_WIDTH-1:0] alu_operand_a =
    op == OP_SHF || op == OP_ADDI ? (rega[3] ? {{(REGISTERS_WIDTH-4){rega[3]}},rega} : {{(REGISTERS_WIDTH-4){1'b0}},rega} + 1) : 
    regs_dat_a; // otherwise regs[a]

// RAM related wiring and registers
reg ram_we; // enabled when 'reg_dat_b' is written to ram address 'rega_dat_a'
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
wire zn_we = is_do_op && ((cs_en && is_cs_op) || (is_alu_op && !is_cs_op)); // update flags if alu op, 'call' or 'return'. note. if return zn-flags from 'Calls' take precedence
wire zn_sel = cs_ret; // if 'zn_we': if 'ret' select flags from from Calls otherwise ALU 
wire zn_clr = cs_call; // if 'zn_we': clears the flags if it is a 'call'. has precedence over 'zn_sel'
wire cs_zf, cs_nf, alu_zf, alu_nf; // z- and n-flag wires between Zn, ALU and Calls

// UartTx related wiring
reg [7:0] utx_dat; // data to send
reg utx_go; // enabled when 'utx_dat' contains data to send and acknowledge 'utx_bsy' low 
wire utx_bsy; // enabled while sending, when going low UartTx waits for 'utx_go' to go low as an acknowledge that data has been sent 

// UartRx related wiring (part 2)
wire [7:0] urx_dat; // last read byte
wire urx_dr; // enabled when data ready
reg urx_go; // enable to start receiving, disable after data received to acknowledge
reg urx_reg_hilo; // read into high or low byte of the register 'urx_reg'

// lights
assign led0_b = 1; // turn off rgb
assign led0_g = 1;
assign led0_r = 1;

reg [5:0] stp; // state of instruction execution

localparam STP_BIT_NEW_INSTRUCTION  = 0;
localparam STP_BIT_WAIT_FOR_ROM     = 1;
localparam STP_BIT_LDI_WAIT_FOR_ROM = 2;
localparam STP_BIT_LDI_LOAD_DATA    = 3;
localparam STP_BIT_UART_SENDING     = 4;
localparam STP_BIT_UART_RECEIVING   = 5;

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
        stp <= 1 << STP_BIT_NEW_INSTRUCTION;
        pc <= 0;
        regs_wd_sel <= 0;
        is_ldi <= 0;
        ldi_ret <= 0;
        ldi_is_ret <= 0;
        regs_we <= 0;
        ram_we <= 0;
        utx_dat <= 0;
        utx_go <= 0;
        urx_reg <= 0;
        urx_regb_sel <= 0;
        urx_reg_hilo <= 0;
        urx_go <= 0;
        led <= 0;
    end else begin
        `ifdef DBG
            $display("%0t: clk+: Zenx: %0d:%0h stp=%0d, doop:%0d, cs_en=%0d, zn=%d%d", $time, pc, instr, stp, is_do_op, cs_en, zn_zf, zn_nf);
        `endif
        if(stp[STP_BIT_NEW_INSTRUCTION]) begin
            // got instruction from rom, execute
            if (is_do_op) begin
                if (cs_call) begin // call
                    pc <= imm12 << 4; // set 'pc'
                    stp <= 1 << STP_BIT_WAIT_FOR_ROM;
                end else if (is_jmp) begin // jmp
                    pc <= pc + {{(ROM_ADDR_WIDTH-12){imm12[11]}},imm12}; // increment 'pc'
                    stp <= 1 << STP_BIT_WAIT_FOR_ROM;
                end else begin
                    if (cs_ret) begin // if instruction had 'ret' flag
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
                            stp <= 1 << STP_BIT_UART_RECEIVING;
                        end
                        3'b010: begin // send blocking
                            utx_dat <= rega[3] ? regs_dat_b[15:8] : regs_dat_b[7:0]; // select the lower or higher bits to send
                            utx_go <= 1; // signal start of transmission
                            stp <= 1 << STP_BIT_UART_SENDING;
                        end
                        3'b111: begin // ledi
                            led <= regb;
                            stp <= 1 << STP_BIT_WAIT_FOR_ROM;
                        end
                        default: $display("!!! unknown IO op");
                        endcase
                    end else if (is_alu_op) begin
                        regs_we <= 1; // enable write back to register
                        regs_wd_sel <= 0; // select alu result for write to 'regb'
                        stp <= 1 << STP_BIT_WAIT_FOR_ROM;
                    end else begin
                        case(op)
                        OP_LDI: begin
                            ldi_reg <= regb; // save the register to which the next instruction data will be written
                            ldi_is_ret <= is_ret;
                            stp <= 1 << STP_BIT_LDI_WAIT_FOR_ROM;
                        end
                        OP_ST: begin
                            ram_we <= 1; // enable ram write
                            stp <= 1 << STP_BIT_WAIT_FOR_ROM;
                        end
                        OP_LD: begin
                            regs_we <= 1; // enable register write
                            regs_wd_sel <= 1; // select ram output for write to 'regb'
                            stp <= 1 << STP_BIT_WAIT_FOR_ROM;
                        end
                        default: $display("!!! unknown instruction");
                        endcase
                    end // is_alu_op else
                end // io || is_alu 
            end else begin // !is_do_op, instruction will not execute
                pc <= pc + (!is_jmp && !cs_call && (op == OP_LDI) ? 2 : 1); // skip 2 instructions if it is 'ldi'
                stp <= 1 << STP_BIT_WAIT_FOR_ROM;
            end // is_do_top else
        end else if(stp[STP_BIT_WAIT_FOR_ROM]) begin // wait one cycle for rom and disable controls
            ram_we <= 0; // disable ram write
            regs_we <= 0; // disable register write
            regs_wd_sel <= 0; // select alu result on the write register data
            urx_regb_sel <= 0; // disable signal that 'regb' is 'urx_reg'
            is_ldi <= 0; // disable flag that instruction is data for 'ldi'
            ldi_ret <= 0; // disable the 'ret' from 'ldi'
            ldi_is_ret <= 0;
            stp <= 1 << STP_BIT_NEW_INSTRUCTION; // done
        end else if(stp[STP_BIT_LDI_WAIT_FOR_ROM]) begin // ldi: wait for rom
            is_ldi <= 1; // signal that next instruction is data
            stp <= 1 << STP_BIT_LDI_LOAD_DATA;
        end else if(stp[STP_BIT_LDI_LOAD_DATA]) begin // ldi: load register
            regs_we <= 1; // enable register write
            regs_wd_sel <= 2; // select register write from rom output
            ldi_ret <= ldi_is_ret;
            if (ldi_is_ret) begin // if 'ldi' had 'ret' flag then return from 'call'
                pc <= cs_pc_out + 1; // get return address from 'Calls'
            end else begin
                pc <= pc + 1; // not a return, increment program counter
            end
            stp <= 1 << STP_BIT_WAIT_FOR_ROM;
        end else if(stp[STP_BIT_UART_SENDING]) begin // utx: while uart busy wait
            if (!utx_bsy) begin
                utx_go <= 0; // acknowledge that transmission is done
                stp <= 1 << STP_BIT_NEW_INSTRUCTION;
            end
        end else if(stp[STP_BIT_UART_RECEIVING]) begin // urx: while data is not ready
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
                stp <= 1 << STP_BIT_WAIT_FOR_ROM;
            end // urx_dr
        end // stp[x]
    end // else rst
end

ROM #(
    .DATA_FILE(ROM_FILE),
    .ADDR_WIDTH(ROM_ADDR_WIDTH),
    .WIDTH(REGISTERS_WIDTH)
) rom ( // 64K x 16b
    .clk(clk),
    .addr(pc),
    .dout(instr)
);

Calls #(
    .ADDR_WIDTH(CALLS_ADDR_WIDTH),
    .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH)
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
    .ADDR_WIDTH(REGISTERS_ADDR_WIDTH),
    .WIDTH(REGISTERS_WIDTH)
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
    .WIDTH(REGISTERS_WIDTH)
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

RAM #(
    .ADDR_WIDTH(RAM_ADDR_WIDTH),
    .WIDTH(REGISTERS_WIDTH)
) ram ( // 64K x 16b
    .clk(clk),
    .we(ram_we),
    .addr(regs_dat_a),
    .din(regs_dat_b),
    .dout(ram_dat_out)
);

UartTx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) utx (
    .rst(rst),
    .clk(clk),
    .data(utx_dat),
    .go(utx_go),
    .tx(uart_tx),
    .bsy(utx_bsy)
);

UartRx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) urx (
    .rst(rst),
    .clk(clk),
    .rx(uart_rx),
    .data(urx_dat),
    .dr(urx_dr),
    .go(urx_go)
);

endmodule

`undef DBG
`default_nettype wire