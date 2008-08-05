/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * 6502 processor emulation implemented with some inspiration by code
 * by David Sharp and Neal Tew.
 *
 * This modules contains all arithmetical and logical instructions:
 * ADC, INX, INY, DEX, DEY, SBC, INC, DEC
 * AND, ORA, EOR, ASL, LSR, ROL, ROR
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

        .global op_21
op_21: @ AND ($FF,X)
        mr_addr_mode_indx
        ands m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 6

        .global op_29
op_29: @ AND #$FF
        mr_pc_arg8
        ands m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 2

        .global op_2d
op_2d: @ AND $FFFF
        mr_addr_mode_abs
        ands m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_31
op_31: @ AND ($FF),Y
        mr_addr_mode_indy       @ this increments m_t on page wraps
        ands m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 5

        .global op_35
op_35: @ AND $FF,X
        mr_addr_mode_zpx
        ands m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 4

        .global op_39
op_39: @ AND $FFFF,Y
        mr_addr_mode_absy       @ this increments m_t on page wraps
        ands m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_3d
op_3d: @ AND $FFFF,X
        mr_addr_mode_absx       @ this increments m_t on page wraps
        ands m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_61
op_61: @ ADC ($FF,X)
        mr_addr_mode_indx
        do_adc
        op_end 2 6

        .global op_65
op_65: @ ADC $FF
        mr_addr_mode_zp
        do_adc
        op_end 2 3

        .global op_69
op_69:  @ ADC #$xx
        mr_pc_arg8
        do_adc
        op_end 2 2

        .global op_6d
op_6d: @ ADC $FFFF
        mr_addr_mode_abs
        do_adc
        op_end 3 4

        .global op_71
op_71: @ ADC ($FF),Y
        mr_addr_mode_indy       @ this increments m_t on page wraps
        do_adc
        op_end 2 5

        .global op_75
op_75: @ ADC $FF,X
        mr_addr_mode_zpx
        do_adc
        op_end 2 4


        .global op_79
op_79: @ ADC $FFFF,Y
        mr_addr_mode_absy       @ this increments m_t on page wraps
        do_adc
        op_end 3 4

        .global op_7d
op_7d: @ ADC $FFFF,X
        mr_addr_mode_absx       @ this increments m_t on page wraps
        do_adc
        op_end 3 4

        .global op_88
op_88: @ DEY
        subs m_y, m_y, #(1<<24) @ dec Y, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_c8
op_c8:  @ INY
        adds m_y, m_y, #(1<<24) @ inc Y, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_ca
op_ca: @ DEX
        subs m_x, m_x, #(1<<24) @ dec X, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_e8
op_e8:  @ INX
        adds m_x, m_x, #(1<<24) @ inc X, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

