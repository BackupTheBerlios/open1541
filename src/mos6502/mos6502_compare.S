/*
 * mos6502 - a 6502 emulator
 *
 * (c) 2008, 2009 Thomas Giesel
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 *
 * Thomas Giesel skoe@directbox.com
 */

#include <lpc213x.h>
#include "mos6502_macros.S"

        .global op_c0
op_c0: @ CPY #$FF
        memr_pc_arg8
        y_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2

        .global op_c1
op_c1: @ CMP ($FF,X)
        memr_addr_mode_indx
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 6

        .global op_c4
op_c4: @ CPY $FF
        memr_addr_mode_zp
        y_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 3

        .global op_c5
op_c5: @ CMP $FF
        memr_addr_mode_zp
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 3

        .global op_c9
op_c9: @ CMP #$FF
        memr_pc_arg8
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2

        .global op_cc
op_cc: @ CPY $FFFF
        memr_addr_mode_abs
        y_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 4

        .global op_cd
op_cd: @ CMP $FFFF
        memr_addr_mode_abs
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 4

        .global op_d1
op_d1: @ CMP ($FF),Y
        memr_addr_mode_indy     @ this increments m_t on page wraps
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 5

        .global op_d5
op_d5: @ CMP $FF,X
        memr_addr_mode_zpx
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 4

        .global op_d9
op_d9: @ CMP $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 4

        .global op_dd
op_dd: @ CMP $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        a_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 4

        .global op_e0
op_e0: @ CPX #$FF
        memr_pc_arg8
        x_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 2

        .global op_e4
op_e4: @ CPX $FF
        memr_addr_mode_zp
        x_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 3

        .global op_ec
op_ec: @ CPX $FFFF
        memr_addr_mode_abs
        x_to_tmp
        cmp m_tmp, m_data, lsl #24
        update_nzc              @ update 6502 flags
        op_end 4
