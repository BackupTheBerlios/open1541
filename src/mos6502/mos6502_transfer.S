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

        .global op_81
op_81: @ STA ($FF,X)
        a_to_data_low
        memw_addr_mode_indx
        op_end 6

        .global op_84
op_84: @ STY $FF
        y_to_data_low
        memw_addr_mode_zp
        op_end 3

        .global op_85
op_85: @ STA $FF
        a_to_data_low
        memw_addr_mode_zp
        op_end 3

        .global op_86
op_86: @ STX $FF
        x_to_data_low
        memw_addr_mode_zp
        op_end 3

        .global op_8a
op_8a: @ TXA
        x_to_tmp
        tmp_to_a
        movs m_tmp, m_tmp
        update_nz
        op_end 2

        .global op_8c
op_8c: @ STY $FFFF
        y_to_data_low
        memw_addr_mode_abs
        op_end 4

        .global op_8d
op_8d: @ STA $FFFF
        a_to_data_low
        memw_addr_mode_abs
        op_end 4

        .global op_8e
op_8e: @ STX $FFFF
        x_to_data_low
        memw_addr_mode_abs
        op_end 4

        .global op_91
op_91: @ STA ($FF),Y
        a_to_data_low
        memw_addr_mode_indy
        op_end 6

        .global op_94
op_94: @ STY $FF,X
        y_to_data_low
        memw_addr_mode_zpx
        op_end 4

        .global op_95
op_95: @ STA $FF,X
        a_to_data_low
        memw_addr_mode_zpx
        op_end 4

        .global op_96
op_96: @ STX $FF,Y
        x_to_data_low
        memw_addr_mode_zpy
        op_end 4

        .global op_98
op_98: @ TYA
        y_to_tmp
        tmp_to_a
        movs m_tmp, m_tmp
        update_nz
        op_end 2

        .global op_99
op_99: @ STA $FFFF,Y
        a_to_data_low
        memw_addr_mode_absy
        op_end 5

        .global op_9d
op_9d: @ STA $FFFF,X
        a_to_data_low
        memw_addr_mode_absx
        op_end 5

        .global op_a0
op_a0:  @ LDY #xx
        memr_pc_arg8
        data_low_to_y
        movs m_data, m_data, lsl #24
        update_nz
        op_end 2

        .global op_a1
op_a1: @ LDA ($FF,X)
        memr_addr_mode_indx
        data_low_to_a
        movs m_data, m_data, lsl #24
        update_nz
        op_end 6

        .global op_a2
op_a2:  @ LDX #xx
        memr_pc_arg8
        data_low_to_x
        movs m_data, m_data, lsl #24
        update_nz
        op_end 2

        .global op_a4
op_a4:  @ LDY $xx
        memr_addr_mode_zp
        data_low_to_y
        movs m_data, m_data, lsl #24
        update_nz
        op_end 3

        .global op_a5
op_a5:  @ LDA $xx
        memr_addr_mode_zp
        data_low_to_a
        movs m_data, m_data, lsl #24
        update_nz
        op_end 3

        .global op_a6
op_a6:  @ LDX $xx
        memr_addr_mode_zp
        data_low_to_x
        movs m_data, m_data, lsl #24
        update_nz
        op_end 3

        .global op_a8
op_a8: @ TAY
        a_to_tmp
        tmp_to_y
        movs m_tmp, m_tmp
        update_nz
        op_end 2

        .global op_a9
op_a9:  @ LDA #xx
        memr_pc_arg8
        data_low_to_a
        movs m_data, m_data, lsl #24
        update_nz
        op_end 2

        .global op_aa
op_aa: @ TAX
        a_to_tmp
        tmp_to_x
        movs m_tmp, m_tmp
        update_nz
        op_end 2

        .global op_ac
op_ac: @ LDY $FFFF
        memr_addr_mode_abs
        data_low_to_y
        movs m_data, m_data, lsl #24
        update_nz
        op_end 4

        .global op_ad
op_ad: @ LDA $FFFF
        memr_addr_mode_abs
        data_low_to_a
        movs m_data, m_data, lsl #24
        update_nz
        op_end 4

        .global op_ae
op_ae: @ LDX $FFFF
        memr_addr_mode_abs
        data_low_to_x
        movs m_data, m_data, lsl #24
        update_nz
        op_end 4

        .global op_b1
op_b1: @ LDA ($FF),Y
        memr_addr_mode_indy
        data_low_to_a
        movs m_data, m_data, lsl #24
        update_nz
        op_end 5

        .global op_b4
op_b4: @ LDY $FF,X
        memr_addr_mode_zpx
        data_low_to_y
        movs m_data, m_data, lsl #24
        update_nz
        op_end 4

        .global op_b5
op_b5: @ LDA $FF,X
        memr_addr_mode_zpx
        data_low_to_a
        movs m_data, m_data, lsl #24
        update_nz
        op_end 4

        .global op_b6
op_b6: @ LDX $FF,Y
        memr_addr_mode_zpy
        data_low_to_x
        movs m_data, m_data, lsl #24
        update_nz
        op_end 4

        .global op_b9
op_b9: @ LDA $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        data_low_to_a
        movs m_data, m_data, lsl #24
        update_nz
        op_end 4

        .global op_bc
op_bc: @ LDY $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        data_low_to_y
        movs m_data, m_data, lsl #24
        update_nz
        op_end 4

        .global op_bd
op_bd: @ LDA $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        data_low_to_a
        movs m_data, m_data, lsl #24
        update_nz
        op_end 4

        .global op_be
op_be: @ LDX $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        data_low_to_x
        movs m_data, m_data, lsl #24
        update_nz
        op_end 4

