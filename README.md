# zen-x
experimental retro 16 bit cpu written in verilog xilinx vivado intended for fpga Cmod S7 from Digilent

under construction, second try at fpga using verilog in xilinx vivado

rom and ram implemented using on board block ram

pre pipeline

2 cycles / instruction

```
                          
                          
                       z   n - r   c      vintage 16 bit cpu
                       e   e   e   a 
                       r   g   t   l      32K 16 bit instructions
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
            / . / . / . / 0 / 1 / 0 0 0 / .... / .... /  addi /
           / . / . / . / 0 / 1 / 1 0 0 / .... / .... /  ldi  /
          / . / . / . / 0 / 1 / 0 1 0 / .... / .... /  ld   /
         / . / . / . / 0 / 1 / 1 1 0 / .... / .... /  st   /
        / . / . / . / 0 / 1 / 0 0 1 / .... / .... /       /
       / . / . / . / 0 / 1 / 1 0 1 / .... / .... /       /
      / . / . / . / 0 / 1 / 0 1 1 / .... / .... /       /
     / . / . / . / 0 / 1 / 1 1 1 / .... / .... /       /
    /---/---/---/---/---/-------/------/------/-------/
   / . / . / 0 / 1 /    immediate 12 << 4    /  call /
  / . / . / 1 / 1 /   signed immediate 12   /  skp  /
 /---/---/---/---/---/-------/------/------/-------/


  op  :       : cyc |
 -----:-------:-----:--------------------------------------
 0000 : add   :  2  : reg[b] += reg[a]
 0001 : sub   :  2  : reg[b] -= reg[a] 
 0010 : or    :  2  : reg[b] |= reg[a] 
 0011 : xor   :  2  : reg[b] ^= reg[a] 
 0100 : and   :  2  : reg[b] &= reg[a] 
 0101 : not   :  2  : reg[b] = ~reg[a] 
 0110 : cp    :  2  : reg[b] = reg[a]
 0111 : shf   :  2  : reg[b] >>= signed imm4 
 -----:-------:-----:--------------------------------------
 1000 : addi  :  2  : reg[b] += signed imm4
 1001 : ldi   :  4  : reg[b] = { next instruction }
 1010 : ld    :  2  : reg[b] = ram[a]
 1011 : st    :  2  : ram[a] = reg[b]
 1100 :       :     :
 1101 :       :     :
 1110 :       :     :
 1111 :       :     :
 -----:-------:-----:--------------------------------------
 
  rc  :       : cyc :
 -----+-------+-----+--------------------------------------
  01  : call  :  2  : pc = imm12 << 4
  11  : skp   :  2  : pc += signed imm12
 -----+-------+-----+--------------------------------------

 any instruction where rc=10 returns from call

```
