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

        .global op_c0
op_c0: @ CPY #$FF
        memr_pc_arg8
        y_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2 2

        .global op_c1
op_c1: @ CMP ($FF,X)
        memr_addr_mode_indx
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2 6

        .global op_c4
op_c4: @ CPY $FF
        memr_addr_mode_zp
        y_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2 3

        .global op_c5
op_c5: @ CMP $FF
        memr_addr_mode_zp
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2 3

        .global op_c9
op_c9: @ CMP #$FF
        memr_pc_arg8
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2 2

        .global op_cc
op_cc: @ CPY $FFFF
        memr_addr_mode_abs
        y_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 3 4

        .global op_cd
op_cd: @ CMP $FFFF
        memr_addr_mode_abs
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 3 4

        .global op_d1
op_d1: @ CMP ($FF),Y
        memr_addr_mode_indy     @ this increments m_t on page wraps
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2 5

        .global op_d5
op_d5: @ CMP $FF,X
        memr_addr_mode_zpx
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2 4

        .global op_d9
op_d9: @ CMP $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 3 4

        .global op_dd
op_dd: @ CMP $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 3 4

        .global op_e0
op_e0: @ CPX #$FF
        memr_pc_arg8
        x_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2 2

        .global op_e4
op_e4: @ CPX $FF
        memr_addr_mode_zp
        x_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2 3

        .global op_ec
op_ec: @ CPX $FFFF
        memr_addr_mode_abs
        x_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 3 4
