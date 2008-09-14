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
#include <mos6502_macros.S>

MACH_DATA_DECLARE = 1
#include <mach_data.S>

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
        ldr     pc, [pc, m_tmp, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word via1w_00, via1w_xx, via1w_02, via1w_03
        .word via1w_xx, via1w_05, via1w_xx, via1w_xx
        .word via1w_xx, via1w_xx, via1w_xx, via1w_xx
        .word via1w_0c, via1w_xx, via1w_xx, via1w_xx

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
        .word via1r_04, via1r_05, via1r_xx, via1r_xx
        .word via1r_xx, via1r_xx, via1r_xx, via1r_xx
        .word via1r_xx, via1r_xx, via1r_xx, via1r_xx


/*******************************************************************************
 * Write to VIA1 PRB (CLOCK, DATA etc.)
 * Currently ignored
 *
 ******************************************************************************/
via1w_00:
        via_report_access_w
        strb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + 0)]
        mov     pc, lr                  @ return

/******************************************************************************
 * Read from VIA1 PRB (CLOCK, DATA etc.)
 * Currently: Return last value written
 *
 ******************************************************************************/
via1r_00:
        ldrb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + 0)]
        via_report_access_r
        mov     pc, lr                  @ return

/******************************************************************************
 * Write to VIA1 Data Direction Register B (CLOCK, DATA etc.)
 * 1541 II writes 0x1a here, i.e. ATN_ACK, DATA, CLOCK OUT, everything else IN.
 * This is hard-coded in our project and cannot be changed.
 *
 ******************************************************************************/
via1w_02:
        strb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + 2)]

        @ we only support value 0x1a to be written here
        cmp     m_data, #0x1a
        bne     via_report_access

        mov     pc, lr                  @ return

/******************************************************************************
 * Write to VIA1 Data Direction Register A  (Parallel cable)
 * Currently ignored, the 1541 II writes 0xff here.
 *
 ******************************************************************************/
via1w_03:
        strb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + 3)]

        @ we only support value 0xff to be written here
        cmp     m_data, #0xff
        bne     via_report_access

        mov     pc, lr                  @ return

/******************************************************************************
 * Write to VIA1 T1CH
 * Write low byte latch, reset T1 interrupt flag.
 *
 ******************************************************************************/
via1w_04:
        strb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + VIA_T1LL)]
        @ todo: reset T1 IRQ flag
        mov     pc, lr                  @ return

/******************************************************************************
 * Read from VIA1 T1CL
 * Return low byte of counter 1
 *
 ******************************************************************************/
via1r_04:
        ldr     m_data, [m_pdata, #VIA1_T1_EXP_OFFSET]

        @ todo: that's not cycle accurate
        sub     m_data, m_data, m_t     @ calc time to exp
        and     m_data, m_data, #0xff   @ isolate low byte
        via_report_access_r
        mov     pc, lr                  @ return

/******************************************************************************
 * Write to VIA1 T1CH
 * Write high byte latch, transfer high:low latch into counter,
 * reset T1 interrupt flag.
 *
 ******************************************************************************/
via1w_05:
        @ We write to high latch first
        strb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + VIA_T1LH)]

        @ take low byte latch and combine them
        ldrb    m_tmp, [m_pdata, #(VIA1_REGS_OFFSET + VIA_T1LL)]
        orr     m_data, m_tmp, m_data, lsl #8

        @ todo: that's not cycle accurate
        @ add current time to it and remember timeout
        add     m_data, m_data, m_t
        str     m_data, [m_pdata, #VIA1_T1_EXP_OFFSET]

        @ todo: reset T1 IRQ flag

        mov     pc, lr                  @ return

/******************************************************************************
 * Read from VIA1 T1CH
 * Return high byte of counter 1
 *
 ******************************************************************************/
via1r_05:
        ldr     m_data, [m_pdata, #VIA1_T1_EXP_OFFSET]

        @ todo: that's not cycle accurate
        sub     m_data, m_data, m_t     @ calc time to exp
        mov     m_data, m_data, lsr# 8  @ get high byte
        and     m_data, m_data, #0xff   @ isolate 8 bits
        via_report_access_r
        mov     pc, lr                  @ return

/******************************************************************************
 * Write to VIA1 Peripheral Control Register
 * Currently ignored, the 1541 II writes 0x01 here.
 * Bit 0: ATN IRQ on positive edge
 *
 ******************************************************************************/
via1w_0c:
        via_report_access_w
        strb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + 3)]
        mov     pc, lr                  @ return

/*******************************************************************************
 * Generic read function for VIA1
 * Write the value to a VIA mirror register.
 *
 ******************************************************************************/
via1w_xx:
        via_report_access_w
        and     m_tmp, m_addr, #0x0f
        add     m_tmp, m_tmp, #VIA1_REGS_OFFSET
        strb    m_data, [m_pdata, m_tmp]
        mov     pc, lr                  @ return

/*******************************************************************************
 * Generic read function for VIA1
 * Return the last value written to a mirror register.
 *
 ******************************************************************************/
via1r_xx:
        and     m_tmp, m_addr, #0x0f
        add     m_tmp, m_tmp, #VIA1_REGS_OFFSET
        ldrb    m_data, [m_pdata, m_tmp]
        via_report_access_r
        mov     pc, lr                  @ return







/*******************************************************************************
 * Write to VIA2 Data Port B (SYNC, Motors, Bit Rates, LED)
 *
 ******************************************************************************/
via2w_00:
        @ via_report_access_w
        strb    m_data, [m_pdata, #(VIA2_REGS_OFFSET + 0)]

        @ Set LED state (this should be implemented a better way...)
        ldr     m_addr, =(DIRTY_LED_PORT + IOPIN)
        ldr     m_tmp, [m_addr]
        tst     m_data, #(1 << 3)
        bicne   m_tmp, #(1 << DIRTY_LED_PIN)
        orreq   m_tmp, #(1 << DIRTY_LED_PIN)
        str     m_tmp, [m_addr]

        mov     pc, lr                  @ return

/******************************************************************************
 * Write to VIA2 Data Direction Register B (SYNC, Motors, Bit Rates, LED)
 * 1541 II writes 0x6f here, everything OUT except SYNC and WRITE PROTECT.
 * At one place 0x08 is written, but with no different functionality intended.
 * This is hard-coded in our project and cannot be changed.
 *
 ******************************************************************************/
via2w_02:
        strb    m_data, [m_pdata, #(VIA2_REGS_OFFSET + 2)]

        @ we only support values 0x6f and 0x08 to be written here
        cmp     m_data, #0x6f
        beq     1f
        cmp     m_data, #0x08
        bne     via_report_access
1:
        mov     pc, lr                  @ return

/******************************************************************************
 * Write to VIA2 Data Direction Register A  (Data to/from head)
 * Currently ignored, the 1541 II writes 0xff here.
 *
 ******************************************************************************/
via2w_03:
        strb    m_data, [m_pdata, #(VIA2_REGS_OFFSET + 3)]

        @ we only support value 0xff and 0x00 to be written here
        cmp     m_data, #0xff
        beq     1f
        cmp     m_data, #0x00
        bne     via_report_access
1:
        mov     pc, lr                  @ return

/******************************************************************************
 * Read from VIA2 Data Port B (SYNC, Motors, Bit Rates, LED)
 * Return last value written
 *
 ******************************************************************************/
via2r_00:
        ldrb    m_data, [m_pdata, #(VIA2_REGS_OFFSET + 0)]
        @ via_report_access_r
        mov     pc, lr                  @ return



/*******************************************************************************
 * Generic write function for VIA1
 * Write the value to a VIA mirror register.
 *
 ******************************************************************************/
via2w_xx:
        via_report_access_w
        and     m_tmp, m_addr, #0x0f
        add     m_tmp, m_tmp, #VIA2_REGS_OFFSET
        strb    m_data, [m_pdata, m_tmp]
        mov     pc, lr                  @ return

/*******************************************************************************
 * Generic read function for VIA2
 * Return the last value written to a mirror register.
 *
 ******************************************************************************/
via2r_xx:
        and     m_tmp, m_addr, #0x0f
        add     m_tmp, m_tmp, #VIA2_REGS_OFFSET
        ldrb    m_data, [m_pdata, m_tmp]
        via_report_access_r
        mov     pc, lr                  @ return