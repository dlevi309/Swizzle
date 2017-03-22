//
//  TBTrampoline.s
//  SwizzleTest
//
//  Created by Tanner on 11/24/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

.text
.global _TBTrampoline
.global _TBTrampolineFP
.align 4

#if __arm64__
_TBTrampolineFP:
    // FP denoted by x12 == x9 == 0xbabefeeddeadbeef
    movz	x9, #0xbabe, lsl #48
    movk	x9, #0xfeed, lsl #32
    movk	x9, #0xdead, lsl #16
    movk	x9, #0xbeef
    mov     x12, x9
    b       _TBTrampoline

_TBTrampoline:
    // Prologue
    stp     x29, x30, [sp, #-16]!       // Save fp and lr
    mov     x29, sp                     // (x29 is frame pointer, not fp)

    // Save general purpose registers
    stp     x11, x12, [sp, #-16]!       // x11 for no reason and x12 for Floating-point flag
    stp     x8, x9, [sp, #-16]!         // x8 for struct return addr and x9 for Floating-point flag
    stp     x6, x7, [sp, #-16]!
    stp     x4, x5, [sp, #-16]!
    stp     x2, x3, [sp, #-16]!
    stp     x0, x1, [sp, #-16]!
    mov     x3, sp                      // General purpose registers in r3
    sub     x4, x4, x4                  // NULL in r4

    // Maybe skip save Floating-point registers
    cmp     x9, x12
    b.ne    landing_func_call

    // Save Floating-point registers
    stp     s6, s7, [sp, #-16]!
    stp     s4, s5, [sp, #-16]!
    stp     s2, s3, [sp, #-16]!
    stp     s0, s1, [sp, #-16]!
    mov     x4, sp                      // Floating-point registers in r4

landing_func_call:

    stp     xzr, x4, [sp, #-16]!        // Save x4 as new Floating-point flag

    // self and _cmd already in
    // x0 and x1, as arg0 and arg1
    //
    // TBTrampolineLanding(self, _cmd, stackArgs, GPRegisters, FPRegisters)
    add     x2, x29, #16                // Stack arguments in r2
    bl      _TBTrampolineLanding        // Replace arguments, get original IMP

    // Save original IMP in x10
    mov     x10, x0

    // Maybe skip restore Floating-point registers
    movz    x9, #0
    cmp     x4, x9
    b.e     restore_gp_registers

    // Restore Floating-point registers
    ldp     s0, s1, [sp], #16
    ldp     s2, s3, [sp], #16
    ldp     s4, s5, [sp], #16
    ldp     s6, s7, [sp], #16

restore_gp_registers:
    // Restore general purpose registers
    ldp     x0, x1, [sp], #16
    ldp     x2, x3, [sp], #16
    ldp     x4, x5, [sp], #16
    ldp     x6, x7, [sp], #16
    ldp     x8, x9, [sp], #16

    // Epilogue
    mov     sp, x29
    ldp     x29, x30, [sp], #16         // `[sp], #16` loads at sp then adds 16 to sp

    // Call original method
    br       x10


#elif __arm__
_TBTrampolineFP:
movt	r12, #0xdead
movw	r12, #0xbeef
movt	r9,  #0xdead
movw	r9,  #0xbeef
b       _TBTrampoline

_TBTrampoline:
    // Prologue
    push    {r7, lr}
    mov     r7, sp                  // Frame pointer

    // Save argument registers
    push    {r3, r2, r1, r0}

    // exit(1), no armv7 support at the moment
    mov     x0, #1
    b       _exit

    // Epilogue
    mov     sp, r7
    pop     {r7, lr}

    // Jump back to Objc land
    b       _TBTrampolineLanding

#else
_TBTrampolineFP:
    xorl	%edi, %edi
    callq   _exit
_TBTrampoline:
    xorl	%edi, %edi
    callq   _exit
#endif
