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

#include <lpc213x.h>
#include "mos6502_macros.S"

        .global op_18
op_18:  @ CLC
        bic m_pc, #MOS6502_C
        op_end 1 2

        .global op_38
op_38:  @ SEC
        orr m_pc, m_pc, #MOS6502_C
        op_end 1 2

        .global op_58
op_58:  @ CLI
        bic m_pc, #MOS6502_I
        op_end 1 2

        .global op_78
op_78:  @ SEI
        orr m_pc, m_pc, #MOS6502_I
        op_end 1 2

        .global op_b8
op_b8:  @ CLV
        bic m_pc, #MOS6502_V
        op_end 1 2

        .global op_d8
op_d8:  @ CLD
        bic m_pc, #MOS6502_D
        op_end 1 2

        .global op_ea
op_ea:  @ NOP
        op_end 1 2

        .global op_f8
op_f8:  @ SED
        orr m_pc, m_pc, #MOS6502_D
        op_end 1 2

        .global op_xx

op_24: @ BIT $FF
op_2c: @ BIT $FFFF
op_00: @ BRK
op_6c: @ JMP ($FFFF)
op_20: @ JSR $FFFF
op_48: @ PHA
op_08: @ PHP
op_68: @ PLA
op_28: @ PLP
op_40: @ RTI
op_60: @ RTS
op_ba: @ TSX
op_9a: @ TXS

op_xx:
        op_end 1 2
