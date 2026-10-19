/*** asmMult.s   ***/
/* Tell the assembler to allow both 16b and 32b extended Thumb instructions */
.syntax unified

/* Tell the assembler that what follows is in data memory    */
.data
.align
 
/* define and initialize global variables that C can access */
/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Jesus Hernandez"  

.align   /* realign so that next mem allocations are on word boundaries */
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global packed_Value,a_Multiplicand,b_Multiplier,a_Sign,b_Sign,prod_Is_Neg,a_Abs,b_Abs,abs_Product,final_Product
.type packed_Value,%gnu_unique_object
.type a_Multiplicand,%gnu_unique_object
.type b_Multiplier,%gnu_unique_object
.type a_Sign,%gnu_unique_object
.type b_Sign,%gnu_unique_object
.type prod_Is_Neg,%gnu_unique_object
.type a_Abs,%gnu_unique_object
.type b_Abs,%gnu_unique_object
.type abs_Product,%gnu_unique_object
.type final_Product,%gnu_unique_object

/* NOTE! These are only initialized ONCE, right before the program runs.
 * If you want these to be 0 every time asmMult gets called, you must set
 * them to 0 at the start of your code!
 */
packed_Value:    .word     0  
a_Multiplicand:  .word     0  
b_Multiplier:    .word     0  
a_Sign:          .word     0  
b_Sign:          .word     0 
prod_Is_Neg:     .word     0  
a_Abs:           .word     0  
b_Abs:           .word     0 
abs_Product:     .word     0
final_Product:   .word     0

 /* Tell the assembler that what follows is in instruction memory    */
.text
.align

    
/********************************************************************
function name: asmMult
function description:
     output = asmMult ()
     
where:
     output: 
     
     function description: See Lab Instructions
     
     notes:
        None
          
********************************************************************/    
.global asmMult
.type asmMult,%function
asmMult:   

    /* save the caller's registers, as required by the ARM calling convention */
    push {r4-r11,LR}
 
.if 0
    /* profs test code. */
    mov r0,r0
.endif
    
    /*** STUDENTS: Place your code BELOW this line!!! **************/
    
    /* Register plan for this function:
     *   r4 = Ra: A unpacked and sign-extended to 32 bits
     *   r5 = Rb: B unpacked and sign-extended to 32 bits
     *   r6 = sign of A (0 = positive or zero, 1 = negative)
     *   r7 = sign of B (0 = positive or zero, 1 = negative)
     *   r8 = 1 if the final product must be negative, else 0
     *   r1, r3 = scratch registers that hold memory addresses
     */
 
    /* Record the original packed input exactly as the caller passed it,
     * before any of r0's bits get shifted around */
    ldr r1, =packed_Value
    str r0, [r1]
 
    /* ---------------- Unpack A (bits 31-16) ----------------
     * An arithmetic shift right by 16 moves A down into the low half and,
     * at the same time, fills the upper half with copies of A's sign bit
     * (bit 31). That one instruction both unpacks and sign-extends A. */
    asr r4, r0, 16
 
    /* ---------------- Unpack B (bits 15-0) -----------------
     * B's sign bit sits at bit 15, so an arithmetic shift can't extend it
     * where it is. First push B up to the top half so its sign bit lands
     * in bit 31 (this also discards A's bits)... */
    lsl r5, r0, 16
    /* ...then shift it back down arithmetically, which returns B to the
     * low half and fills the upper half with copies of B's sign bit */
    asr r5, r5, 16
 
    /* ---------------- Save A and its sign / magnitude ---------------- */
    /* Store the sign-extended A as the multiplicand */
    ldr r1, =a_Multiplicand
    str r4, [r1]
 
    /* Bit 31 of a sign-extended value is 1 only when it is negative, so
     * moving bit 31 down to bit 0 yields exactly 0 or 1 for a_Sign */
    lsr r6, r4, 31
    ldr r1, =a_Sign
    str r6, [r1]
 
    /* Start |A| as a copy of A; it only needs changing if A is negative */
    mov r2, r4
    cmp r6, 0
    beq a_abs_ready         /* A is positive or zero: already its own |A| */
    rsb r2, r2, 0           /* A is negative: |A| = 0 - A */
a_abs_ready:
    ldr r1, =a_Abs
    str r2, [r1]
 
    /* ---------------- Save B and its sign / magnitude ---------------- */
    /* Store the sign-extended B as the multiplier */
    ldr r1, =b_Multiplier
    str r5, [r1]
 
    /* Same trick as for A: bit 31 tells us whether B is negative */
    lsr r7, r5, 31
    ldr r1, =b_Sign
    str r7, [r1]
 
    /* Start |B| as a copy of B; it only needs changing if B is negative */
    mov r2, r5
    cmp r7, 0
    beq b_abs_ready         /* B is positive or zero: already its own |B| */
    rsb r2, r2, 0           /* B is negative: |B| = 0 - B */
b_abs_ready:
    ldr r1, =b_Abs
    str r2, [r1]
 
    /* ---------------- Decide the sign of the product ----------------
     * Default to "not negative". A product involving zero is zero, which
     * is never negative, so skip the sign check if either input is 0. */
    mov r8, 0
    cmp r4, 0
    beq sign_decided        /* A is 0, so the product is 0 */
    cmp r5, 0
    beq sign_decided        /* B is 0, so the product is 0 */
    /* Both inputs are nonzero: the product is negative only when exactly
     * one input is negative, i.e. when the two sign bits differ (XOR) */
    eor r8, r6, r7
sign_decided:
    ldr r1, =prod_Is_Neg
    str r8, [r1]
 
    /* ---------------- Shift-and-add multiplication ----------------
     * Multiply the magnitudes so the loop only ever deals with positive
     * numbers; the sign gets applied afterward.
     *   r0 = multiplicand (|A|), doubled each pass
     *   r1 = multiplier   (|B|), halved each pass to expose the next bit
     *   r2 = running product */
    ldr r1, =a_Abs
    ldr r0, [r1]            /* multiplicand = |A| */
    ldr r1, =b_Abs
    ldr r1, [r1]            /* multiplier = |B| */
    mov r2, 0               /* product starts at 0 before any partial sums */
 
mult_loop:
    cmp r1, 0
    beq mult_done           /* no 1 bits left in the multiplier: product is complete */
    tst r1, 1
    beq skip_add            /* current multiplier bit is 0: this partial product is 0 */
    add r2, r2, r0          /* current multiplier bit is 1: add the shifted multiplicand */
skip_add:
    lsl r0, r0, 1           /* next multiplier bit is worth twice as much, so double the multiplicand */
    lsr r1, r1, 1           /* bring the next multiplier bit into bit 0 for testing */
    b mult_loop
 
mult_done:
    /* The loop only used magnitudes, so this result is always positive */
    ldr r3, =abs_Product
    str r2, [r3]
 
    /* ---------------- Apply the sign to get the final product -------- */
    cmp r8, 0
    beq final_ready         /* product should be positive: keep it as is */
    rsb r2, r2, 0           /* product should be negative: final = 0 - |product| */
final_ready:
    ldr r3, =final_Product
    str r2, [r3]
 
    /* Return the signed product to the caller in r0 */
    mov r0, r2
    b done
    
    /*** STUDENTS: Place your code ABOVE this line!!! **************/

done:    
    mov r0,r0 /* these are do-nothing lines to deal with IDE mem display bug */
    mov r0,r0 

    /* restore the caller's registers, as required by the 
     * ARM calling convention 
     */
    pop {r4-r11,LR}

    mov pc, lr	 /* asmMult return to caller */
   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




