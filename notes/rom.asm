func print: # r1: strptr, r2:strlen, r3, r4
    ldi 0xfffe r3        # r3 = 0xfffe
    and r2 r3            # r3 &= r2
    ifz jmp done         # ifz jmp loop_end
    loop:                # loop:
        ld r1 r4         #     r4 = [r1]
        iowl r4          #     wl r4
        iowh r4          #     wh r4
        addi 1 r1        #     r1 += 1
        addi -1 r3       #     r3 -= 1
        ifp jmp loop     #     ifp jmp loop
    done:                # loop_end:
        addi 1 r3        # r3 += 1  // reusing r3 which is now 0
        and r2 r3        # r2 &= r3
        ifp ld r1 r4     # ifp r4 = [r1]
        ifp iowl r4 ret  # ifp wl r4 ret

func input: # r1: bufptr, r2: buflen
        ldi 0x000a r3    # r3 = 0x000a
        ldi 0x0a00 r4    # r4 = 0x0a00
        ldi 0x00ff r5    # r5 = 0x00ff
        ldi 0xff00 r6    # r6 = 0xff00
        cp r1 r10        # r10 = r1
        xor r9 r9        # r9 = 0
        loop:            # loop:
            addi 1 r9    #     r9++
            rdl r7       #     rdl r7
            st r10 r7    #     [r10] = r7
            cp r7 r8     #     r8 = r7
            and r5 r8    #     r8 &= r5
            xor r3 r8    #     r8 ^= r3
            ifz jmp done #     ifz jmp done
            rdh r7       #     rdh r7
            st r10 r7    #     [r10] = r7
            cp r7 r8     #     r8 = r7
            and r6 r8    #     r8 &= r6
            xor r4 r8    #     r8 ^= r4
            ifz jmp done #     ifz jmp done
            addi -1 r2   #     r2--
            ifz jmp done #     ifz jmp done
            addi r9      #     r9++
            jmp loop     # jmp loop
        done:            # done:
        cp r9 r2 ret     # r2 = r9 ret
                         # 

fun main:                
    ldi strbuf r11       # r11 = &strbuf
    ld r11 r1            # r1 = [r11]
    ldi strlen r11       # r11 = &strlen
    ld r11 r2            # r2 = [r11]
    cp r2 r12            # r12 = r2
    loop:                # loop:
        call input       #   input()
        call print       #   print()
        cp r12 r2        #   r2 = r12
    jmp loop             # jmp loop
    