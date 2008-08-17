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

        .global op_08
op_08: @ PHP
        @ todo: Fix order and position of bits
        mov     m_data, m_pc, lsr #24

        @ get SP
        ldr     lr, =mos6502_sp
        ldrb    m_tmp, [lr]

        @ PUSH
        ldr     m_addr, =(c1541_ram + 0x100)
        strb    m_data, [m_addr, m_tmp]

        @ dec SP, we'll only store one byte so it wraps automatically
        sub     m_tmp, m_tmp, #1

        @ save SP
        strb    m_tmp, [lr]
        op_end 1 3

        .global op_28
op_28: @ PLP
        @ get SP
        ldr     lr, =mos6502_sp
        ldrb    m_tmp, [lr]

        @ inc SP, wrap it
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PULL
        ldr     m_addr, =(c1541_ram + 0x100)
        ldrb    m_data, [m_addr, m_tmp]

        bic     m_pc, m_pc, #(0xff << 24)
        orr     m_pc, m_data, lsl #24

        @ save SP
        strb    m_tmp, [lr]
        op_end 1 4

        .global op_48
op_48: @ PHA
        mov     m_data, m_a, lsr #24

        @ get SP
        ldr     lr, =mos6502_sp
        ldrb    m_tmp, [lr]

        @ PUSH
        ldr     m_addr, =(c1541_ram + 0x100)
        strb    m_data, [m_addr, m_tmp]

        @ dec SP, we'll only store one byte so it wraps automatically
        sub     m_tmp, m_tmp, #1

        @ save SP
        strb    m_tmp, [lr]
        op_end 1 3

        .global op_68
op_68: @ PLA
        @ get SP
        ldr     lr, =mos6502_sp
        ldrb    m_tmp, [lr]

        @ inc SP, wrap it
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PULL
        ldr     m_addr, =(c1541_ram + 0x100)
        ldrb    m_data, [m_addr, m_tmp]

        movs    m_a, m_data, lsl #24

        @ save SP
        strb    m_tmp, [lr]
        update_nz
        op_end 1 4

        .global op_ba
op_ba: @ TSX
        @ get SP
        ldr     lr, =mos6502_sp
        ldrb    m_x, [lr]
        movs    m_x, m_x, lsl #24
        update_nz
        op_end 1 2

        .global op_9a
op_9a: @ TXS
        ldr     lr, =mos6502_sp
        mov     m_tmp, m_x, lsr #24
        strb    m_tmp, [lr]
        op_end 1 2
