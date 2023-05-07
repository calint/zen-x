# zen-x
experimental retro 16 bit cpu written in verilog xilinx vivado intended for fpga Cmod S7 from Digilent

under construction, second try at fpga using verilog in xilinx vivado

rom and ram implemented in block ram

? cycles / instruction

```
                          n
                          e
                      z n-x-c r   vintage 16 bit cpu
                      e e t a e
                      r g   l t     32K 16 bit instructions
                      o a   l u     64K 16 bit data
                        t     r     16  16 bit registers
                        i     n     33  MHz
                        v
                        e

                 | 0 | 1 | 2 | 3 | 4 | 5 - 7 | 8-11 | 12-15|
                 |---|---|---|---|---|-------|------|------|
                 | z | n | x | r | c | o p   | rega | regb |
                 |---|---|---|---|---|-------|------|------|
                 / . / . / . / . / 0 / 0 0 0 / .... / .... /  xor
                / . / . / . / . / 0 / 0 0 1 / imm4 / .... /  addi
               / . / . / . / . / 0 / 0 1 0 / src  / dst  /  copy
              / . / . / . / . / 0 / 0 1 1 / 0000 / .... /  not
             / . / . / . / . / 0 / 0 1 1 / imm4 / .... /  shift
            / . / . / . / . / 0 / 1 0 0 / ...  / .... /  sub
           / . / . / . / . / 0 / 1 0 1 / .... / .... /  add
          / . / . / . / . / 0 / 1 1 0 / addr / dst  /  load
         / . / . / . / . / 0 / 1 1 1 / addr / src  /  store
        / . / . / 0 / 0 / 1 / immediate 11 << 3   /  call
       / . / . / 0 / 1 / 1 / 0 0 0 / 0000 / .... /  loop
      / . / . / 0 / 1 / 1 / 1 0 0 / immediate 8 /  skip
     / . / . / 0 / 1 / 1 / 0 1 0 / 0000 / .... /  loadi

    op :       :
   ----:-------:-----------------------------------------------------
   000 : xor   : reg[b]=~reg[a] 
   100 : addi  : reg[b]+=imm4
   010 : copy  : reg[b]=reg[a]
   110 : not   : reg[b]=~reg[b]
   110 : shift : reg[b]>>=imm4 (negative imm4 means 'left')
   001 : sub   : reg[b]-=reg[a] 
   101 : add   : reg[b]+=reg[a]
   011 : load  : reg[b]=ram[a]
   111 : store : ram[a]=reg[b]

   page cr = 11

    op :       :
   ----:-------:-----------------------------------------------------
   000 : loop  : start loop with counter value from reg[b]
   001 : skip  : pc+=imm8+1
   010 : loadi : reg[b]={next instruction}
   011 :       : 
   100 :       :
   101 :       : 
   110 :       :
   111 :       :
```
