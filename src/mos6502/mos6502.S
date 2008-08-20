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
 *
 * Todo:
 * - Check if we can afford more registers to get more speed like PocketNES
 *   does
 * - Check if we can put at least X and Y into one ARM register to get one
 *   banked register free
 * - Implement BCD mode
 *
 * Implementing opcodes:
 * On entry:
 * Registers r8..r12 (m_t, m_a, m_x, m_y, m_pc) contain the current emulation
 * state as described in mos6502_macros.S.
 *
 * m_t
 *      contains the time when the instruction starts to be executed.
 *
 * m_addr
 *      points to the host memory corresponding to the client PC. So it
 *      points to the current opcode. This will be used by the
 *      macros memr_pc_arg8 or me memr_pc_arg16
 *
 * m_data, m_addr and m_tmp can be used as scratch registers and don't need to
 * be restored
 *
 */

#include <arm7tdmi.h>
#include <lpc213x.h>

#include "mos6502_macros.S"

        .bss

@ !!!!! Keep offsets in sync with MOS6502_XXX_OFFSET constants !!!!!
        .global mos6502_data
mos6502_data:

        .global mos6502_sp
mos6502_sp:
.word   0

        .global mos6502_a
mos6502_areg:
.word   0

        .global mos6502_x
mos6502_xreg:
.word   0

        .global mos6502_y
mos6502_yreg:
.word   0

        .code 32
        .text

/*******************************************************************************
 * Initialize all registers, load the PC with the reset vector. Put the 
 * processor into single step mode.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_reg_init
mos6502_reg_init:
        push    {lr}

        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ point to base address of timer0 registers
        ldr     m_ptimer, =T0IR

        @ point to base address of data storage
        ldr     m_pdata, =mos6502_data

        @ set all regs to 0
        mov     m_tmp, #0
        tmp_to_a
        tmp_to_x
        tmp_to_y

        @ initialize SP
        mov     m_tmp, #0xff
        tmp_to_sp

        @ Read start address from reset vector
        mov     m_addr, #0xff00
        add     m_addr, m_addr, #0xfc
        memr_addr
        mov     m_pc, m_data
        add     m_addr, m_addr, #1
        memr_addr
        add     m_pc, m_data, lsl #8

        @ set single step mode
        orr     m_pc, m_pc, #MOS6502_S

        @ restore old processor and interrupt state, return
        msr     cpsr_c, r3
        pop     {pc}

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

        stmia   r0!, {m_t}   @ time
        a_to_data_low
        stmia   r0!, {m_data}
        x_to_data_low
        stmia   r0!, {m_data}
        y_to_data_low
        stmia   r0!, {m_data}
        stmia   r0!, {m_pc}  @ pc, flags

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
 * Return a value != 0 if the client machine is stopped, i.e. in single step 
 * mode.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_is_stopped
mos6502_is_stopped:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        and     r0, m_pc, #MOS6502_S

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
        mov     m_addr, r0
        memr_addr
        mov     r0, m_data

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
        @ write T0TC
        ldr     r0, [m_ptimer, #(T0TC - T0IR)]
        add     r0, r0, #2
        @ write T0MCR0
        str     r0, [m_ptimer, #(T0MR0 - T0IR)]

        @ remember pointer to T0TC, because m_ptimer will become invisible
        add     r1, m_ptimer, #(T0TC - T0IR)

        @ restore old processor and interrupt state
        msr     cpsr_c, r3

step_wait:
        ldr     r2, [r1]
        subs    r3, r0, r2
        bpl     step_wait

        mov     pc, lr

/*******************************************************************************
 * Start execution or continue from single step mode. If the emulation is not 
 * stopped this function does nothing.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_run
mos6502_run:
        @ remember old processor and interrupt state
        mrs r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ Check for single step mode
        tst m_pc, #MOS6502_S
        beq 1f

        @ Delete bit for single step mode
        bic m_pc, m_pc, #MOS6502_S

        @ program the timer match register 0 to expire in 2 us
        ldr     m_t, [m_ptimer, #(T0TC - T0IR)]
        add     m_t, m_t, #2
        str     m_t, [m_ptimer, #(T0MR0 - T0IR)]
1:
        b exit_fiq_mode

