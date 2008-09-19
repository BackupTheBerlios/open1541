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

#include <mos6502_macros.S>
#include "via.h"
#include "via_macros.S"

MACH_DATA_DECLARE = 1
#include <mach_data.S>


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
        .word via2w_00, via2w_xx, via2w_02, via2w_03
        .word via2w_xx, via2w_xx, via2w_xx, via2w_xx
        .word via2w_xx, via2w_xx, via2w_xx, via2w_xx
        .word via2w_xx, via2w_xx, via2w_xx, via2w_xx

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
 * Generic write function for VIA2
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
