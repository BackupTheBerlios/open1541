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

/*
 * References:
 * [1] mos_6522.pdf: MCS6522 Versatile Interface Adapter;
 *     MOS Technology Inc. 1977
 */

/* This file must be included into mos6502_fiq.S */

#include <autoconf.h>

#include <mos6502_macros.S>
#include "via.h"

MACH_DATA_DECLARE = 1
#include <mach_data.S>


/*******************************************************************************
 * Update the IRQ flag of VIA1.
 *
 * This does only update MOS6502_IRQ_VIA1 in m_flags, which represents the
 * physical IRQ line of the VIA chip. IFR is written to memory in this macro.
 * For performance reasons bit 7 of IFR is only updated when IFR is read by an
 * emulated instruction.
 *
 * In:  m_data      Value of IFR with updated bits 0..6
 *
 * Out: m_tmp       Changed
 *
 ******************************************************************************/
.macro via1_update_irq_flag

        strb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + VIA_IFR)]
        ldrb    m_tmp, [m_pdata, #(VIA1_REGS_OFFSET + VIA_IER)]
        and     m_tmp, m_data
        ands    m_tmp, #0x7f
        // set update flag for IRQ
        biceq   m_flags, #MOS6502_IRQ_VIA1
        orrne   m_flags, #MOS6502_IRQ_VIA1
.endm



.macro via1_check_irqs

        // get IEC state
        ldr     m_tmp, =IEC_IN_PORT
        ldr     m_tmp, [m_tmp]

        // check CA1 (1 = active = low on bus)
        tst     m_tmp, #ATN_IN_BIT

        // inactive => next active edge can be detected again
        biceq   m_flags, #VIA1_CA1_LOW_EDGE_DETECTED
        beq     1f

        // it's low, check if the last edge has been registered already
        tst     m_flags, #VIA1_CA1_LOW_EDGE_DETECTED
        bne     1f

        // remember that we realized this edge
        orr     m_flags, #VIA1_CA1_LOW_EDGE_DETECTED

        // flag it
        ldrb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + VIA_IFR)]
        orr     m_data, #VIA_IM_CA1

        via1_update_irq_flag
1:
.endm
