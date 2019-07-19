/* Some macros taken from https://github.com/ARM-software/arm-trusted-firmware/blob/master/include/common/aarch64/asm_macros.S */
/*
 * Copyright (c) 2013-2017, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */
 

/*
 * Declare the exception vector table, enforcing it is aligned on a
 * 2KB boundary, as required by the ARMv8 architecture.
 * Use zero bytes as the fill value to be stored in the padding bytes
 * so that it inserts illegal AArch64 instructions. This increases
 * security, robustness and potentially facilitates debugging.
 */
.macro vector_base  label, section_name=.vectors
.section \section_name, "ax"
.align 11, 0
\label:
.endm

/*
 * Create an entry in the exception vector table, enforcing it is
 * aligned on a 128-byte boundary, as required by the ARMv8 architecture.
 * Use zero bytes as the fill value to be stored in the padding bytes
 * so that it inserts illegal AArch64 instructions. This increases
 * security, robustness and potentially facilitates debugging.
 */
.macro vector_entry  label, section_name=.vectors
.cfi_sections .debug_frame
.section \section_name, "ax"
.align 7, 0
.type \label, %function
.func \label
.cfi_startproc
\label:
.endm

/*
 * This macro verifies that the given vector doesnt exceed the
 * architectural limit of 32 instructions. This is meant to be placed
 * immediately after the last instruction in the vector. It takes the
 * vector entry as the parameter
 */
.macro check_vector_size since
    .endfunc
    .cfi_endproc
    .if (. - \since) > (32 * 4)
        .error "Vector exceeds 32 instructions"
    .endif
.endm

.macro save_all_regs
    sub     sp, sp, #0x110
    stp     x0, x1, [sp, #0x00]
    stp     x2, x3, [sp, #0x10]
    stp     x4, x5, [sp, #0x20]
    stp     x6, x7, [sp, #0x30]
    stp     x8, x9, [sp, #0x40]
    stp     x10, x11, [sp, #0x50]
    stp     x12, x13, [sp, #0x60]
    stp     x14, x15, [sp, #0x70]
    stp     x16, x17, [sp, #0x80]
    stp     x18, x19, [sp, #0x90]
    stp     x20, x21, [sp, #0xA0]
    stp     x22, x23, [sp, #0xB0]
    stp     x24, x25, [sp, #0xC0]
    stp     x26, x27, [sp, #0xD0]
    stp     x28, x29, [sp, #0xE0]

    mrs     x20, sp_el1
    mrs     x21, elr_el2
    mrs     x22, spsr_el2

    stp     x30, x20, [sp, #0xF0]
    stp     x21, x22, [sp, #0x100]
.endm

/* Actual Vectors for Exosphere. */
.global exosphere_vectors
vector_base exosphere_vectors

/* Current EL, SP0 */
.global unknown_exception
unknown_exception:
vector_entry synch_sp0
    b .
    check_vector_size synch_sp0

vector_entry irq_sp0
    b unknown_exception
    check_vector_size irq_sp0

vector_entry fiq_sp0
    b unknown_exception
    check_vector_size fiq_sp0

vector_entry serror_sp0
    b unknown_exception
    check_vector_size serror_sp0

/* Current EL, SPx */
vector_entry synch_spx
    b unknown_exception
    check_vector_size synch_spx

vector_entry irq_spx
    b unknown_exception
    check_vector_size irq_spx

vector_entry fiq_spx
    b unknown_exception
    check_vector_size fiq_spx

vector_entry serror_spx
    b unknown_exception
    check_vector_size serror_spx
    
/* Lower EL, A64 */
vector_entry synch_a64
    save_all_regs

    mov     x0, sp
    mrs     x1, esr_el2

    bl      . // FIXME!

    b       _restore_all_regs
    check_vector_size synch_a64

vector_entry irq_a64
    b unknown_exception
    check_vector_size irq_a64

vector_entry fiq_a64
    b unknown_exception
    check_vector_size fiq_a64

vector_entry serror_a64
    b unknown_exception
    check_vector_size serror_a64


/* Lower EL, A32 */
vector_entry synch_a32
    b unknown_exception
    check_vector_size synch_a32

vector_entry irq_a32
    b unknown_exception
    check_vector_size irq_a32

vector_entry fiq_a32
    b fiq_a64
    .endfunc
    .cfi_endproc
/* To save space, insert in an unused vector segment. */
_restore_all_regs:
    ldp     x30, x20, [sp, #0xF0]
    ldp     x21, x22, [sp, #0x100]

    msr     sp_el1, x20
    msr     elr_el2, x21
    msr     spsr_el2, x22

    ldp     x0, x1, [sp, #0x00]
    ldp     x2, x3, [sp, #0x10]
    ldp     x4, x5, [sp, #0x20]
    ldp     x6, x7, [sp, #0x30]
    ldp     x8, x9, [sp, #0x40]
    ldp     x10, x11, [sp, #0x50]
    ldp     x12, x13, [sp, #0x60]
    ldp     x14, x15, [sp, #0x70]
    ldp     x16, x17, [sp, #0x80]
    ldp     x18, x19, [sp, #0x90]
    ldp     x20, x21, [sp, #0xA0]
    ldp     x22, x23, [sp, #0xB0]
    ldp     x24, x25, [sp, #0xC0]
    ldp     x26, x27, [sp, #0xD0]
    ldp     x28, x29, [sp, #0xE0]

    add     sp, sp, #0x110
    eret

vector_entry serror_a32
    b unknown_exception
    check_vector_size serror_a32
