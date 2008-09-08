/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
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
 */

#include <autoconf.h>
#include <lpc213x.h>
#include <via.h>
#include <mos6502.h>
#include <mos6502_macros.S>


/*******************************************************************************
 * Write byte m_data to the VIA 1 register in m_addr.
 *
 * In:  m_addr      Client address
 *      m_data      The byte to be written
 *
 * Out: m_addr      Changed (!!!)
 *      m_tmp       Changed
 *
 ******************************************************************************/
        .global memw_via1
memw_via1:
        @ a VIA has 16 regs, remove the other bits
        and     m_tmp, m_addr, #0x0f

        @ jump to the register handler address
        ldr pc, [pc, m_tmp, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word via1w_00,  viaw_none, via1w_02,  via1w_03
        .word viaw_none, viaw_none, viaw_none, viaw_none
        .word viaw_none, viaw_none, viaw_none, viaw_none
        .word via1w_0c,  viaw_none, viaw_none, viaw_none

/*******************************************************************************
 * Read a byte from the VIA 1 register in m_addr and return it in m_data.
 *
 * In:  m_addr      Client address
 *
 * Out: m_data      The byte
 *      m_tmp       Changed
 *
 ******************************************************************************/
        .global memr_via1
memr_via1:
        @ a VIA has 16 regs, remove the other bits
        and     m_tmp, m_addr, #0x0f

        @ jump to the register handler address
        ldr pc, [pc, m_tmp, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word via1r_00, via1r_xx, via1r_xx, via1r_xx
        .word via1r_xx, via1r_xx, via1r_xx, via1r_xx
        .word via1r_xx, via1r_xx, via1r_xx, via1r_xx
        .word via1r_xx, via1r_xx, via1r_xx, via1r_xx

/*******************************************************************************
 * Write byte m_data to the VIA 2 register in m_addr.
 *
 * In:  m_addr      Client address
 *      m_data      The byte to be written
 *
 * Out: m_addr      Changed (!!!)
 *      m_tmp       Changed
 *
 ******************************************************************************/
        .global memw_via2
memw_via2:
        @ a VIA has 16 regs, remove the other bits
        and     m_tmp, m_addr, #0x0f

        @ jump to the register handler address
        ldr pc, [pc, m_tmp, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word via2w_00,  viaw_none, viaw_none, viaw_none
        .word viaw_none, viaw_none, viaw_none, viaw_none
        .word viaw_none, viaw_none, viaw_none, viaw_none
        .word viaw_none, viaw_none, viaw_none, viaw_none

/*******************************************************************************
 * Read a byte from the VIA 2 register in m_addr and return it in m_data.
 *
 * In:  m_addr      Client address
 *
 * Out: m_data      The byte
 *      m_tmp       Changed
 *
 ******************************************************************************/
        .global memr_via2
memr_via2:
        @ a VIA has 16 regs, remove the other bits
        and     m_tmp, m_addr, #0x0f

        @ jump to the register handler address
        ldr pc, [pc, m_tmp, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word via2r_00, via2r_xx, via2r_xx, via2r_xx
        .word via2r_xx, via2r_xx, via2r_xx, via2r_xx
        .word via2r_xx, via2r_xx, via2r_xx, via2r_xx
        .word via2r_xx, via2r_xx, via2r_xx, via2r_xx


/*******************************************************************************
 * Write to VIA1 PRB (CLOCK, DATA etc.)
 * Currently ignored
 *
 ******************************************************************************/
via1w_00:
        strb    m_data, [m_pdata, #(MOS6502_VIA1_REGS_OFFSET + 0)]
        mov     pc, lr                  @ return

/******************************************************************************
 * Read from VIA1 PRB (CLOCK, DATA etc.)
 * Return last value written
 *
 ******************************************************************************/
via1r_00:
        ldrb    m_data, [m_pdata, #(MOS6502_VIA1_REGS_OFFSET + 0)]
        mov     pc, lr                  @ return

/******************************************************************************
 * Write to VIA1 Data Direction Register B (CLOCK, DATA etc.)
 * 1541 II writes 0x1a here, i.e. ATN_ACK, DATA, CLOCK OUT, everything else IN.
 * This is hard-coded in our project and cannot be changed.
 *
 ******************************************************************************/
via1w_02:
        strb    m_data, [m_pdata, #(MOS6502_VIA1_REGS_OFFSET + 2)]
        mov     pc, lr                  @ return

/******************************************************************************
 * Write to VIA1 Data Direction Register A  (Parallel cable)
 * Currently ignored, the 1541 II writes 0xff here.
 *
 ******************************************************************************/
via1w_03:
        strb    m_data, [m_pdata, #(MOS6502_VIA1_REGS_OFFSET + 3)]
        mov     pc, lr                  @ return

/******************************************************************************
 * Write to VIA1 Peripheral Control Register
 * Currently ignored, the 1541 II writes 0x01 here.
 * Bit 0: ATN IRQ on positive edge
 *
 ******************************************************************************/
via1w_0c:
        strb    m_data, [m_pdata, #(MOS6502_VIA1_REGS_OFFSET + 3)]
        mov     pc, lr                  @ return

/*******************************************************************************
 * Write to VIA2 Data Port B (SYNC, Motors, Bit Rates, LED)
 *
 ******************************************************************************/
via2w_00:
        strb    m_data, [m_pdata, #(MOS6502_VIA2_REGS_OFFSET + 0)]

        @ Set LED state (this should be implemented in a better way...)
        ldr     m_addr, =(DIRTY_LED_PORT + IOPIN)
        ldr     m_tmp, [m_addr]
        tst     m_data, #(1 << 3)
        bicne   m_tmp, #(1 << DIRTY_LED_PIN)
        orreq   m_tmp, #(1 << DIRTY_LED_PIN)
        str     m_tmp, [m_addr]

        mov     pc, lr                  @ return

/******************************************************************************
 * Read from VIA2 Data Port B (SYNC, Motors, Bit Rates, LED)
 * Return last value written
 *
 ******************************************************************************/
via2r_00:
        ldrb    m_data, [m_pdata, #(MOS6502_VIA2_REGS_OFFSET + 0)]
        mov     pc, lr                  @ return

/*******************************************************************************
 * Report unimplemented VIA write attempts
 *
 * Write the value to a mirror register and print an error message.
 *
 * In:  m_addr      Client address
 *      m_data      The byte to be written
 *
 * Out: m_addr      Changed (!!!)
 *      m_tmp       Changed
 *
 ******************************************************************************/
viaw_none:
        stmfd   sp!, {r1 - r5, lr}

        and     m_tmp, m_addr, #0x0f
        cmp     m_addr, #VIA2_BASE
        addlo   m_tmp, m_tmp, #MOS6502_VIA1_REGS_OFFSET
        addge   m_tmp, m_tmp, #MOS6502_VIA2_REGS_OFFSET
        strb    m_data, [m_pdata, m_tmp]

        mov     r4, m_addr          @ save regs
        mov     r5, m_data

        mov     r0, m_pc, lsl #16   @ get PC, remove flags
        mov     r0, r0, lsr #16
        bl      uart_puthex

        mov     r0, #':'
        bl      uart_putc

        mov     r0, r4              @ address
        bl      uart_puthex

        mov     r0, #'='
        bl      uart_putc

        mov     r0, r5              @ data
        bl      uart_puthex

        bl      uart_putcrlf

        ldmfd   sp!, {r1 - r5, pc}

/*******************************************************************************
 * Generic read function for VIA1
 * Return the last value written to a mirror register.
 *
 ******************************************************************************/
via1r_xx:
        and     m_tmp, m_addr, #0x0f
        add     m_tmp, m_tmp, #MOS6502_VIA1_REGS_OFFSET
        ldrb    m_data, [m_pdata, m_tmp]
        mov     pc, lr                  @ return

/*******************************************************************************
 * Generic read function for VIA2
 * Return the last value written to a mirror register.
 *
 ******************************************************************************/
via2r_xx:
        and     m_tmp, m_addr, #0x0f
        add     m_tmp, m_tmp, #MOS6502_VIA2_REGS_OFFSET
        ldrb    m_data, [m_pdata, m_tmp]
        mov     pc, lr                  @ return
