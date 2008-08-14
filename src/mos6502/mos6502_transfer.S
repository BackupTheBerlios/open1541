/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * 6502 processor emulation implemented with some inspiration by code
 * by David Sharp and Neal Tew.
 *
 * This modules contains all transfer, load and store instructions: 
 * LDA, LDX, LDY, STA, STX, STY, TAX, TAY, TSX, TXA, TXS, TYA
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

        .global op_81
op_81: @ STA ($FF,X)
        mov m_data, m_a, lsr #24
        memw_addr_mode_indx
        op_end 2 6

        .global op_85
op_85: @ STA $FF
        mov m_data, m_a, lsr #24
        memw_addr_mode_zp
        op_end 2 3

        .global op_8a
op_8a: @ TXA
        movs m_a, m_x
        update_nz
        op_end 1 2

        .global op_8d
op_8d: @ STA $FFFF
        mov m_data, m_a, lsr #24
        memw_addr_mode_abs
        op_end 3 4

        .global op_91
op_91: @ STA ($FF),Y
        mov m_data, m_a, lsr #24
        memw_addr_mode_indy
        op_end 2 6

        .global op_95
op_95: @ STA $FF,X
        mov m_data, m_a, lsr #24
        memw_addr_mode_zpx
        op_end 2 4

        .global op_98
op_98: @ TYA
        movs m_a, m_y
        update_nz
        op_end 1 2

        .global op_99
op_99: @ STA $FFFF,Y
        mov m_data, m_a, lsr #24
        memw_addr_mode_absy
        op_end 3 5

        .global op_9d
op_9d: @ STA $FFFF,X
        mov m_data, m_a, lsr #24
        memw_addr_mode_absx
        op_end 3 5

        .global op_a0
op_a0:  @ LDY #xx
        memr_pc_arg8
        movs m_y, m_data, lsl #24
        update_nz
        op_end 2 2

        .global op_a1
op_a1: @ LDA ($FF,X)
        memr_addr_mode_indx
        movs m_a, m_data, lsl #24
        update_nz
        op_end 2 6

        .global op_a2
op_a2:  @ LDX #xx
        memr_pc_arg8
        movs m_x, m_data, lsl #24
        update_nz
        op_end 2 2

        .global op_a4
op_a4:  @ LDY $xx
        memr_addr_mode_zp
        movs m_y, m_data, lsl #24
        update_nz
        op_end 2 3

        .global op_a5
op_a5:  @ LDA $xx
        memr_addr_mode_zp
        movs m_a, m_data, lsl #24
        update_nz
        op_end 2 3

        .global op_a6
op_a6:  @ LDX $xx
        memr_addr_mode_zp
        movs m_x, m_data, lsl #24
        update_nz
        op_end 2 3

        .global op_a8
op_a8: @ TAY
        movs m_y, m_a
        update_nz
        op_end 1 2

        .global op_a9
op_a9:  @ LDA #xx
        memr_pc_arg8
        movs m_a, m_data, lsl #24
        update_nz
        op_end 2 2

        .global op_aa
op_aa: @ TAX
        movs m_x, m_a
        update_nz
        op_end 1 2

        .global op_ac
op_ac: @ LDY $FFFF
        memr_addr_mode_abs
        movs m_y, m_data, lsl #24
        update_nz
        op_end 3 4

        .global op_ad
op_ad: @ LDA $FFFF
        memr_addr_mode_abs
        movs m_a, m_data, lsl #24
        update_nz
        op_end 3 4

        .global op_ae
op_ae: @ LDX $FFFF
        memr_addr_mode_abs
        movs m_x, m_data, lsl #24
        update_nz
        op_end 3 4

        .global op_b1
op_b1: @ LDA ($FF),Y
        memr_addr_mode_indy
        movs m_a, m_data, lsl #24
        update_nz
        op_end 2 5

        .global op_b4
op_b4: @ LDY $FF,X
        memr_addr_mode_zpx
        movs m_y, m_data, lsl #24
        update_nz
        op_end 2 4

        .global op_b5
op_b5: @ LDA $FF,X
        memr_addr_mode_zpx
        movs m_a, m_data, lsl #24
        update_nz
        op_end 2 4

        .global op_b6
op_b6: @ LDX $FF,Y
        memr_addr_mode_zpy
        movs m_x, m_data, lsl #24
        update_nz
        op_end 2 4

        .global op_b9
op_b9: @ LDA $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        movs m_a, m_data, lsl #24
        update_nz
        op_end 3 4

        .global op_bc
op_bc: @ LDY $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        movs m_y, m_data, lsl #24
        update_nz
        op_end 3 4

        .global op_bd
op_bd: @ LDA $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        movs m_a, m_data, lsl #24
        update_nz
        op_end 3 4

        .global op_be
op_be: @ LDX $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        movs m_x, m_data, lsl #24
        update_nz
        op_end 3 4

