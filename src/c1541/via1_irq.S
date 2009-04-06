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

#include <lpc213x.h>

#include <mos6502_macros.S>
#include "via.h"
#include "via_macros.S"

MACH_DATA_DECLARE = 1
#include <mach_data.S>

.macro via1_check_irqs

        // get IEC state
        ldr     m_tmp, =IEC_IN_PORT
        ldr     m_tmp, [m_tmp]

        // check CA1 (1 = active = low on bus)
        tst     m_tmp, #ATN_IN_BIT

        // inactive => next active edge can be detected again
        bicne   m_flags, #VIA1_CA1_LOW_EDGE_DETECTED
        bne     1f

        // it's low, check if the last edge has been registered already
        tst     m_flags, #VIA1_CA1_LOW_EDGE_DETECTED
        bne     m_flags, #VIA1_CA1_LOW_EDGE_DETECTED

        // we see this low level the first time, flag it
        ldrb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + VIA_IFR)]
        orr     m_data, #(VIA_IM_IRQ | VIA_IM_CA1)
        strb    m_data, [m_pdata, #(VIA1_REGS_OFFSET + VIA_IFR)]
1:
        // update IRQ
        ldrb    m_tmp, [m_pdata, #(VIA1_REGS_OFFSET + VIA_IER)]
        and     m_tmp, m_data
        ands    m_tmp, #0x7f
        beq     2f
        // set flags for IRQ
        orr     m_flags, #MOS6502_IRQ_VIA1
        orr     m_data, #VIA_IM_IRQ
        strb    m_tmp, [m_pdata, #(VIA1_REGS_OFFSET + VIA_IER)]
2:
.endm
