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
        and     m_addr, m_addr, #0x0f

        @ jump to the register handler address
        ldr pc, [pc, m_addr, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word via1w_00,  viaw_none, viaw_none, viaw_none
        .word viaw_none, viaw_none, viaw_none, viaw_none
        .word viaw_none, viaw_none, viaw_none, viaw_none
        .word viaw_none, viaw_none, viaw_none, viaw_none

        @ write to VIA1 PRB (CLOCK, DATA etc.)
via1w_00:
        strb    m_data, [m_ptimer, #(MOS6502_VIA1_REGS_OFFSET + VIA_PRB)]
        mov     pc, lr                  @ return

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
        and     m_addr, m_addr, #0x0f

        @ jump to the register handler address
        ldr pc, [pc, m_addr, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word via1r_00,  viar_none, viar_none, viar_none
        .word viar_none, viar_none, viar_none, viar_none
        .word viar_none, viar_none, viar_none, viar_none
        .word viar_none, viar_none, viar_none, viar_none

        @ read from VIA1 PRB (CLOCK, DATA etc.)
via1r_00:
        ldrb    m_data, [m_ptimer, #(MOS6502_VIA1_REGS_OFFSET + VIA_PRB)]
        mov     pc, lr                  @ return

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
        and     m_addr, m_addr, #0x0f

        @ jump to the register handler address
        ldr pc, [pc, m_addr, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word via2w_00,  viaw_none, viaw_none, viaw_none
        .word viaw_none, viaw_none, viaw_none, viaw_none
        .word viaw_none, viaw_none, viaw_none, viaw_none
        .word viaw_none, viaw_none, viaw_none, viaw_none

        @ write to VIA2 Data Port B (SYNC, Motors, Bit Rates, LED)
via2w_00:
        strb    m_data, [m_ptimer, #(MOS6502_VIA2_REGS_OFFSET + VIA_PRB)]

        @ Check LED state (this should be implemented in a better way...)
        ldr     m_addr, =(DIRTY_LED_PORT + IOPIN)
        ldr     m_tmp, [m_addr]
        tst     m_data, #(1 << 3)
        bicne   m_tmp, #(1 << DIRTY_LED_PIN)
        orreq   m_tmp, #(1 << DIRTY_LED_PIN)
        str     m_tmp, [m_addr]

        mov     pc, lr                  @ return

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
        and     m_addr, m_addr, #0x0f

        @ jump to the register handler address
        ldr pc, [pc, m_addr, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word via2r_00,  viar_none, viar_none, viar_none
        .word viar_none, viar_none, viar_none, viar_none
        .word viar_none, viar_none, viar_none, viar_none
        .word viar_none, viar_none, viar_none, viar_none

        @ read from VIA2 Data Port B (SYNC, Motors, Bit Rates, LED)
via2r_00:
        ldrb    m_data, [m_ptimer, #(MOS6502_VIA2_REGS_OFFSET + VIA_PRB)]
        mov     pc, lr                  @ return


viar_none:
        mov     m_data, #0xff
viaw_none:
        mov     pc, lr                  @ return
