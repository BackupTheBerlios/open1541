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

op_06: @ ASL $FF
op_16: @ ASL $FF,X
op_0e: @ ASL $FFFF
op_1e: @ ASL $FFFF,X
op_24: @ BIT $FF
op_2c: @ BIT $FFFF
op_00: @ BRK
op_c6: @ DEC $FF
op_d6: @ DEC $FF,X
op_ce: @ DEC $FFFF
op_de: @ DEC $FFFF,X
op_e6: @ INC $FF
op_f6: @ INC $FF,X
op_ee: @ INC $FFFF
op_fe: @ INC $FFFF,X
op_6c: @ JMP ($FFFF)
op_20: @ JSR $FFFF
op_4a: @ LSR A
op_46: @ LSR $FF
op_56: @ LSR $FF,X
op_4e: @ LSR $FFFF
op_5e: @ LSR $FFFF,X
op_48: @ PHA
op_08: @ PHP
op_68: @ PLA
op_28: @ PLP
op_2a: @ ROL A
op_26: @ ROL $FF
op_36: @ ROL $FF,X
op_2e: @ ROL $FFFF
op_3e: @ ROL $FFFF,X
op_6a: @ ROR A
op_66: @ ROR $FF
op_76: @ ROR $FF,X
op_6e: @ ROR $FFFF
op_7e: @ ROR $FFFF,X
op_40: @ RTI
op_60: @ RTS
op_85: @ STA $FF
op_95: @ STA $FF,X
op_8d: @ STA $FFFF
op_9d: @ STA $FFFF,X
op_99: @ STA $FFFF,Y
op_81: @ STA ($FF,X)
op_91: @ STA ($FF),Y
op_86: @ STX $FF
op_96: @ STX $FF,Y
op_8e: @ STX $FFFF
op_84: @ STY $FF
op_94: @ STY $FF,X
op_8c: @ STY $FFFF
op_ba: @ TSX
op_9a: @ TXS

op_xx:
        op_end 1 2
