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

#include <lpc213x.h>
#include "mos6502_macros.S"

        .global op_48
op_48: @ PHA
        mov     m_data, m_a, lsr #24

        @ Get SP
        @ todo: Use the new offset idea to access this
        ldr     m_tmp, =mos6502_sp
        ldrb    m_tmp, [m_tmp]

        @ PUSH
        ldr     m_addr, =(c1541_ram + 0x100)
        strb    m_data, [m_addr, m_tmp]

        @ dec SP, we'll only store one byte so it wraps automatically
        sub     m_tmp, m_tmp, #1

        @ write SP
        @ todo: Use the new offset idea to access this
        ldr     m_addr, =mos6502_sp
        strb    m_tmp, [m_addr]

        op_end 1 3
