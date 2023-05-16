    ldi 0x1234 r1
    ldi 0xabcd r2
    ldi 0xffff r3
    st r2 r1 # ram[0xabcd]=0x1234
    st r1 r3
    ld r2 r6
    ld r1 r4
    st r3 r1
    ld r3 r5
    addi 1 r4
    addi -1 r4
    add r3 r4
    sub r3 r4
    or r4 r6
    xor r6 r6
    and r4 r6
    not r4 r6
    cp r1 r6
    shf 1 r6
    shf -1 r6
    ifz ldi 0x0001 r7
    cp r4 r4
    ifn ldi 0x0001 r7
    ifp jmp lbl1
    jmp lbl1
    ifp add r0 r0 # 0x000 
    ifp add r0 r0 # 0x000

lbl1:
    call x0030
    ifp call x0040
    ifz call x0040
    ifp ldi 0x0040 r9
    ifz ldi 0x0040 r9
    ifp jmp x007
    ifz jmp x007
    ifn call x0050
    jmp x007

    ifp add r0 r0 # 0x0000
    ifp add r0 r0 # 0x0000
    ifp add r0 r0 # 0x0000
    ifp add r0 r0 # 0x0000
    ifp add r0 r0 # 0x0000
 
x0030: func
    addi 1 r8 ret
x007:
    ldi 0x4548 r9
    wl r9
    wh r9
    ldi 0x4c4c r9
    wl r9
    wh r9
    ldi 0x204f r9
    wl r9
    wh r9
echo:
    rl r10
    wl r10
    jmp echo

x0040:
    ifp add r0 r0
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 

    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 

    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 

    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 

x0050: func
    call x0060
    addi 2 r8 ret

    ifp add r0 r0 
    ifp add r0 r0 
    
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 

    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 

    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 

x0060: func
    ifn addi 2 r8 ret
    ifz addi 2 r8 ret
    ifp addi 2 r8 ret
    ifp add r0 r0 

    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 

    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 

    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 
    ifp add r0 r0 
