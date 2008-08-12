/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * 6502 processor emulation implemented with some inspiration by code
 * by David Sharp and Neal Tew.
 *
 * This modules contains all logical instructions:
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

        .global op_01
op_01: @ ORA ($FF,X)
        mr_addr_mode_indx
        orrs m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 6

        .global op_05
op_05: @ ORA $FF
        mr_addr_mode_zp
        orrs m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 3

        .global op_09
op_09: @ ORA #$FF
        mr_pc_arg8
        orrs m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 2

        .global op_0a
op_0a: @ ASL A
        movs    m_a, m_a, asl #1
        update_nzc
        op_end 1 2

        .global op_0d
op_0d: @ ORA $FFFF
        mr_addr_mode_abs
        orrs m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_11
op_11: @ ORA ($FF),Y
        mr_addr_mode_indy       @ this increments m_t on page wraps
        orrs m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 5

        .global op_15
op_15: @ ORA $FF,X
        mr_addr_mode_zpx
        orrs m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 4

        .global op_19
op_19: @ ORA $FFFF,Y
        mr_addr_mode_absy       @ this increments m_t on page wraps
        orrs m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_1d
op_1d: @ ORA $FFFF,X
        mr_addr_mode_absx       @ this increments m_t on page wraps
        orrs m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_21
op_21: @ AND ($FF,X)
        mr_addr_mode_indx
        ands m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 6

        .global op_25
op_25: @ AND $FF
        mr_addr_mode_zp
        ands m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 3

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

        .global op_41
op_41: @ EOR ($FF,X)
        mr_addr_mode_indx
        eors m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 6

        .global op_45
op_45: @ EOR $FF
        mr_addr_mode_zp
        eors m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 3

        .global op_49
op_49: @ EOR #$FF
        mr_pc_arg8
        eors m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 2

        .global op_4d
op_4d: @ EOR $FFFF
        mr_addr_mode_abs
        eors m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_51
op_51: @ EOR ($FF),Y
        mr_addr_mode_indy       @ this increments m_t on page wraps
        eors m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 5

        .global op_55
op_55: @ EOR $FF,X
        mr_addr_mode_zpx
        eors m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 2 4

        .global op_59
op_59: @ EOR $FFFF,Y
        mr_addr_mode_absy       @ this increments m_t on page wraps
        eors m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_5d
op_5d: @ EOR $FFFF,X
        mr_addr_mode_absx       @ this increments m_t on page wraps
        eors m_a, m_a, r0, lsl #24
        update_nz               @ update 6502 flags N and Z
        op_end 3 4
