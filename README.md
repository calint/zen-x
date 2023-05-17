# zen-x
experimental retro 16 bit cpu written in verilog xilinx vivado intended for fpga Cmod S7 from Digilent

pre pipeline

2 cycles / instruction

```
                          
                          
                       z   n - r   c      vintage 16 bit cpu
                       e   e   e   a 
                       r   g   t   l      64K 16 bit instructions
                       o   a   u   l      64K 16 bit data
                           t   r          16  16 bit registers
                           i   n          64  calls stack
                           v              66  MHz
                           e

                     | 0 | 1 | 2 | 3 |   4 - 7   | 8-11 | 12-15|
                     |---|---|---|---|-----------|------|------|
                     | z | n | r | c |   op      | rega | regb |
                     |---|---|---|---|---|-------|------|------|--------
                     / . / . / . / 0 / 0 / 0 0 0 / .... / .... /  add  /
                    / . / . / . / 0 / 0 / 1 0 0 / .... / .... /  sub  /
                   / . / . / . / 0 / 0 / 0 1 0 / .... / .... /  or   /
                  / . / . / . / 0 / 0 / 1 1 0 / .... / .... /  xor  /
                 / . / . / . / 0 / 0 / 0 0 1 / .... / .... /  and  /
                / . / . / . / 0 / 0 / 1 0 1 / ...  / .... /  not  /
               / . / . / . / 0 / 0 / 0 1 1 / .... / .... /  cp   /
              / . / . / . / 0 / 0 / 1 1 1 / imm4 / .... /  shf  /
             /---/---/---/---/---/-------/------/------/-------/
            / . / . / . / 0 / 1 / 0 0 0 / imm4 / .... /  addi /
           / . / . / . / 0 / 1 / 1 0 0 / 0000 / .... /  ldi  /
          / . / . / . / 0 / 1 / 0 1 0 / .... / .... /  ld   /
         / . / . / . / 0 / 1 / 1 1 0 / .... / .... /  st   /
        / . / . / . / 0 / 1 / 0 0 1 / .... / .... /       /
       / . / . / . / 0 / 1 / 1 0 1 / .... / .... /       /
      / . / . / . / 0 / 1 / 0 1 1 / .... / .... /       /
     / . / . / . / 0 / 1 / 1 1 1 / .... / .... /       /
    /---/---/---/---/---/-------/------/------/-------/
   / . / . / 0 / 1 /    immediate 12 << 4    /  call /
  / . / . / 1 / 1 /   signed immediate 12   /  jmp  /
 /---/---/---/---/---/-------/------/------/-------/
 \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 0100 \ .... \  wl   \
  \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 0101 \ .... \  wh   \
   \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 0110 \ .... \  rl   \
    \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 0111 \ .... \  rh   \
     \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 1100 \ .... \       \
      \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 1101 \ .... \       \
       \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 1110 \ .... \       \
        \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 1111 \ .... \       \
 

  op  :       : cyc |
 -----:-------:-----:--------------------------------------
 0000 : add   :  2  : reg[b] += reg[a]
 0010 : sub   :  2  : reg[b] -= reg[a] 
 0100 : or    :  2  : reg[b] |= reg[a] 
 0110 : xor   :  2  : reg[b] ^= reg[a] 
 1000 : and   :  2  : reg[b] &= reg[a] 
 1010 : not   :  2  : reg[b] = ~reg[a] 
 1100 : cp    :  2  : reg[b] = reg[a]
 1110 : shf   :  2  : reg[b] >>= (imm4>=0?++imm4:-imm4)
 -----:-------:-----:--------------------------------------
 0001 : addi  :  2  : reg[b] += (imm4>=0?++imm4:-imm4)
 0011 : ldi   :  4  : reg[b] = { next instruction }
 0101 : ld    :  2  : reg[b] = ram[a]
 0111 : st    :  2  : ram[a] = reg[b]
 1001 :       :     :
 1011 :       :     :
 1101 :       :     :
 1111 :       :     : 
 -----:-------:-----:--------------------------------------

  rc  :       : cyc :
 -----+-------+-----+--------------------------------------
  01  : call  :  2  : pc = imm12 << 4
  11  : jmp   :  2  : pc += signed imm12
 -----+-------+-----+--------------------------------------

i/o
 |z|n|r|c| op |rega|regb| mnemo | description
 |-+-+-+-+----+----+----+-------+--------------------------------------
 |.|.|.|0|1100|0100|....|  wl   | uart blocking write lower regs[b]
 |.|.|.|0|1100|0101|....|  wh   | uart blocking write higher regs[b]
 |.|.|.|0|1100|0110|....|  rl   | uart blocking read lower regs[b]
 |.|.|.|0|1100|0111|....|  rh   | uart blocking read higher regs[b]
 |.|.|.|0|1100|1100|....|       |
 |.|.|.|0|1100|1101|....|       |
 |.|.|.|0|1100|1110|....|       |
 |.|.|.|0|1100|1111|....|       |

zn flags in instructions are compared with current flags
instruction executes according to:
 * zn=11 : always
 * zn=00 : positive number
 * zn=10 : zero
 * zn=01 : negative number

instructions with rc=10 return from call
  does not apply on ldi (todo)

use 'zasm' to compile assembler code. see 'rom.asm' for sample code.

how-to with Vivado v2022.2:
 * connect fpga board Cmod S7 from digilent.com
 * run synthesis, run implementation, program device
 * find out which tty is on the usb connected to the card (i.e. /dev/ttyUSB1)
 * connect with terminal at 9600 baud, 8 bits, 1 stop bit, no parity 
 * "HELLO" is the prompt
 * after the tests and prompt the program enters a read / write loop (echo)
 * button 0 is reset, click it to restart and display the prompt
 * provided ROM is meant for tests run in the simulator


```