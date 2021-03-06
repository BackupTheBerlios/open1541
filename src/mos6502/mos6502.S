/*
 * mos6502 - a 6502 emulator
 *
 * (c) 2008, 2009 Thomas Giesel
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 *
 * Thomas Giesel skoe@directbox.com
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
 * - Put SP into high byte, so wrapping needn't to be done manually
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

#include <autoconf.h>
#include <arm7tdmi.h>
#include <lpc213x.h>
#include <via.h>

#include "mos6502_macros.S"

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
        ldr     m_pdata, =mach_data

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
        orr     m_pc, m_data, lsl #8

        pc_client_to_host

        @ set single step mode
        orr     m_flags, m_flags, #MOS6502_S

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

        mov     m_addr, r0
        stmia   m_addr!, {m_t}   @ time

        a_to_data_low
        stmia   m_addr!, {m_data}

        x_to_data_low
        stmia   m_addr!, {m_data}

        y_to_data_low
        stmia   m_addr!, {m_data}

        sp_to_data
        stmia   m_addr!, {m_data}

        pc_host_to_client m_data
        stmia   m_addr!, {m_data}

        stmia   m_addr!, {m_flags}

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

        pc_host_to_client r0

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

        and     r0, m_flags, #(MOS6502_S | MOS6502_P)

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
 * Write r1 to emulated memory pointed to by r0.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_write_mem
mos6502_write_mem:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        mov     m_addr, r0
        mov     m_data, r1
        memw_data_to_addr

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
        orr m_flags, m_flags, #MOS6502_S

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

        @ Check for single step or breakpoint mode
        tst     m_flags, #(MOS6502_S | MOS6502_P)
        beq     exit_fiq_mode

        @ possibly only the P flag was set but we want to single step now
        bic     m_flags, m_flags, #MOS6502_P
        orr     m_flags, m_flags, #MOS6502_S

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
 * Start execution or continue from single step or break mode. If the emulation
 * is not stopped this function does nothing.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_run
mos6502_run:
        @ remember old processor and interrupt state
        mrs r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ Check for single step or break mode
        tst m_flags, #(MOS6502_S | MOS6502_P)
        beq 1f

        @ Delete bit for single step / break mode (in case it's set)
        bic m_flags, m_flags, #(MOS6502_S | MOS6502_P)

        @ program the timer match register 0 to expire in 2 us
        ldr     m_t, [m_ptimer, #(T0TC - T0IR)]
        add     m_t, m_t, #2
        str     m_t, [m_ptimer, #(T0MR0 - T0IR)]
1:
        b exit_fiq_mode

/*******************************************************************************
 * Set (r0 != 0) or reset (r0 == 0) the simulated IRQ line. This line is
 * wire-ored with the other IRQ sources.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_irqsim
mos6502_irqsim:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ Set/reset IRQ source bit
        cmp     r0, #0
        biceq   m_flags, m_flags, #MOS6502_IRQ_SIM
        orrne   m_flags, m_flags, #MOS6502_IRQ_SIM

        b       exit_fiq_mode

/*******************************************************************************
 * End an opcode emulation, called from FIQ mode.
 *
 * Set the CPU emulation timer to expire in 'time' microseconds.
 * If the emulated CPU is in single step mode, the new time is calculated but
 * not programmed to the hardware timer. The timer IRQ is Ack'd in any case.
 * Exit FIQ mode.
 *
 * In:  m_t     Current client CPU time
 *      time    Number of microseconds for current operation
 *
 * Out: m_t     Increased by 'time'
 *
 ******************************************************************************/
        .global mos6502_op_end
mos6502_op_end:
        @ Ack timer 0 interrupt
        mov     m_tmp, #TIR_MR0
        str     m_tmp, [m_ptimer, #(T0IR - T0IR)]

#if CONFIG_BREAKPOINTS
        pc_host_to_client lr            @ convert client PC, result into lr

        @ Check if PC points to a break point
        add     m_addr, m_pdata, #MOS6502_BP_OFFSET
check_next_bp:
        ldrh    m_tmp, [m_addr], #2     @ load BP and post-increment addr
        cmp     m_tmp, #0
        beq     end_check_bp            @ end if terminating 0 was found

        cmp     m_tmp, lr               @ does PC match this BP?
        bne     check_next_bp

        orr     m_flags, m_flags, #MOS6502_P  @ breakpoint mode

end_check_bp:
#endif

        @ program the timer match register if not in single step nor
        @ breakpoint mode
        tst     m_flags, #(MOS6502_S | MOS6502_P)
        streq   m_t, [m_ptimer, #(T0MR0 - T0IR)] @ store to T0MR0

        ret_fiq
