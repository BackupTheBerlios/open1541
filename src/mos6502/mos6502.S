/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * 6502 processor emulation implemented with some inspiration by code
 * by David Sharp and Neal Tew.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

/*
 * Known limitations:
 * - Multibyte instructions at the end of memory are not executed correctly,
 *   the PC doesn't wrap around to $0000 in the middle of an instruction.
 * - Decimal mode not implemented yet
 *
 * Implementing opcodes:
 * On entry:
 * Registers r8..r12 (m_t, m_a, m_x, m_y, m_pc) contain the current emulation
 * state as described in mos6502_macros.S.
 *
 * m_t contains the time when the instruction starts to be executed.
 *
 * r2  points to the native memory corresponding to the emulated PC. So it
 *     points to the byte behind the current opcode. This will be used by the
 *     macros me memr_pc_arg8 or me memr_pc_arg16
 *
 * r0 to r2 can be used as scratch registers and don't need to be restored
 *
 */

#include <arm7tdmi.h>
#include <lpc213x.h>

#include "mos6502_macros.S"


        .code 32
        .text

/*******************************************************************************
 *
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_reg_init
mos6502_reg_init:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ set time to start exec in 1 ms
        ldr     r1, =T0TC
        ldr     m_t, [r1]
        add     m_t, m_t, #1024
        ldr     r1, =T0MR0
        str     m_t, [r1]

        @ set all regs to 0
        mov     m_a, #0
        mov     m_x, #0
        mov     m_y, #0

        @ todo: Read start address from reset vector
        mov     m_pc, #0

        b       exit_fiq_mode

/*******************************************************************************
 * Copy the processor regs into mos6502_regs_t pointed to by r0.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_store_regs
mos6502_store_regs:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        stmia   r0!, {r8}   @ time
        mov     r1, r9, lsr#24  @ a
        stmia   r0!, {r1}
        mov     r1, r10, lsr#24 @ x
        stmia   r0!, {r1}
        mov     r1, r11, lsr#24 @ y
        stmia   r0!, {r1}
        stmia   r0!, {r12}  @ pc, flags

        b       exit_fiq_mode

/*******************************************************************************
 * Return the emulated PC in R0. To be called from system mode.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_get_pc
mos6502_get_pc:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ copy PC to R0, shift away unused bits
        mov     r0, m_pc, lsl #16
        mov     r0, r0, lsr #16

        b       exit_fiq_mode

/*******************************************************************************
 * Read from emulated memory pointed to by r0, return the result in r0.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_read_mem
mos6502_read_mem:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ read memory and return
        memr_r0
        b       exit_fiq_mode

/*******************************************************************************
 * Put the 6502 into single step mode.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_stop
mos6502_stop:
        @ remember old processor and interrupt state
        mrs r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ Set single step mode
        orr m_pc, m_pc, #MOS6502_S

exit_fiq_mode:
        @ restore old processor and interrupt state, return
        msr cpsr_c, r3
        mov pc, r14

/*******************************************************************************
 * Execute one instruction. If the emulation is not in single step mode
 * this function does nothing.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_step
mos6502_step:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ Check for single step mode
        tst     m_pc, #MOS6502_S
        beq     exit_fiq_mode

        @ program the timer match register 0 to expire in 2 us
        ldr     r1, =T0TC
        ldr     r0, [r1]
        add     r0, r0, #2
        add     r1, r1, #(T0MR0 - T0TC) @ point to T0MCR0 now
        str     r0, [r1]

        @ restore old processor and interrupt state
        msr     cpsr_c, r3

        @ wait until IRQ time is over
        sub     r1, r1, #(T0MR0 - T0TC) @ point to T0TC again
step_wait:
        ldr     r2, [r1]
        subs    r3, r0, r2
        bpl     step_wait

        mov     pc, lr

/*******************************************************************************
 * Continue from single step mode. If the emulation is not in single step mode
 * this function does nothing.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_continue
mos6502_continue:
        @ remember old processor and interrupt state
        mrs r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ Check for single step mode
        tst m_pc, #MOS6502_S
        beq 1f

        @ Delete bit for single step mode
        bic m_pc, #MOS6502_S

        @ program the timer match register 0 to expire in 2 us
        ldr r1, =T0TC
        ldr m_t, [r1]
        add m_t, m_t, #2
        add r1, r1, #(T0MR0 - T0TC)
        str m_t, [r1]
1:
        b exit_fiq_mode

