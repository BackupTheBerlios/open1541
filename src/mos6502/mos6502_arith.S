/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * 6502 processor emulation implemented with some inspiration by code
 * by David Sharp and Neal Tew.
 *
 * This modules contains all arithmetical instructions:
 * ADC, INX, INY, DEX, DEY, SBC, INC, DEC
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

@ Do an ADC, the argument is in m_data[7:0]
.macro do_adc
        movs    m_tmp, m_pc, lsl #3     @ set ARM C from 6502 C
                                        @ if CS: prepare summand
        mvncs   m_tmp, #0xff000000      @     set bits 0-23 so ARM C will work
        orrcs   m_tmp, m_tmp, m_data, lsl #24 @ put summand into 24-31
                                        @ else prepare summand if CC:
        movcc   m_tmp, m_data, lsl #24  @     put summand into 24-31
        adcs    m_a, m_a, m_tmp         @ perform ADC and set ARM flags
        update_nzcv
.endm

@ Do an SBC, the argument is in m_data[7:0]
.macro do_sbc
        movs    m_tmp, m_pc, lsl #3     @ set ARM C from 6502 C
        sbcs    m_a, m_a, m_data, lsl #24

        @ clear unused bits (may be 1 because of C)
        ands    m_a, m_a, #(0xff << 24)
        update_nzcv
.endm

        .global op_61
op_61: @ ADC ($FF,X)
        memr_addr_mode_indx
        do_adc
        op_end 2 6

        .global op_65
op_65: @ ADC $FF
        memr_addr_mode_zp
        do_adc
        op_end 2 3

        .global op_69
op_69:  @ ADC #$FF
        memr_pc_arg8
        do_adc
        op_end 2 2

        .global op_6d
op_6d: @ ADC $FFFF
        memr_addr_mode_abs
        do_adc
        op_end 3 4

        .global op_71
op_71: @ ADC ($FF),Y
        memr_addr_mode_indy     @ this increments m_t on page wraps
        do_adc
        op_end 2 5

        .global op_75
op_75: @ ADC $FF,X
        memr_addr_mode_zpx
        do_adc
        op_end 2 4

        .global op_79
op_79: @ ADC $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        do_adc
        op_end 3 4

        .global op_7d
op_7d: @ ADC $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
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

        .global op_e1
op_e1: @ SBC ($FF,X)
        memr_addr_mode_indx
        do_sbc
        op_end 2 6

        .global op_e8
op_e8:  @ INX
        adds m_x, m_x, #(1<<24) @ inc X, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_e5
op_e5: @ SBC $FF
        memr_addr_mode_zp
        do_sbc
        op_end 2 3

        .global op_e9
op_e9: @ SBC #$FF
        memr_pc_arg8
        do_sbc
        op_end 2 2

        .global op_ed
op_ed: @ SBC $FFFF
        memr_addr_mode_abs
        do_sbc
        op_end 3 4

        .global op_f1
op_f1: @ SBC ($FF),Y
        memr_addr_mode_indy     @ this increments m_t on page wraps
        do_sbc
        op_end 2 5

        .global op_f5
op_f5: @ SBC $FF,X
        memr_addr_mode_zpx
        do_sbc
        op_end 2 4

        .global op_f9
op_f9: @ SBC $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        do_sbc
        op_end 3 4

        .global op_fd
op_fd: @ SBC $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        do_sbc
        op_end 3 4

