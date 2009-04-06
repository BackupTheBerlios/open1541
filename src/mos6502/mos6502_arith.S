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

@ Do an ADC, the argument is in m_data[7:0]
.macro do_adc
        movs    m_tmp, m_flags, lsl #3     @ set ARM C from 6502 C
        a_to_tmp                        @ if CS: prepare summand
        mvncs   lr, #0xff000000         @     set bits 0-23 so ARM C will work
        orrcs   lr, lr, m_data, lsl #24 @ put summand into 24-31
                                        @ else prepare summand if CC:
        movcc   lr, m_data, lsl #24     @     put summand into 24-31
        adcs    m_tmp, m_tmp, lr        @ perform ADC and set ARM flags

        tmp_to_a
        update_nzcv
.endm

@ Do an SBC, the argument is in m_data[7:0]
.macro do_sbc
        movs    m_tmp, m_flags, lsl #3     @ set ARM C from 6502 C
        a_to_tmp
        sbcs    m_tmp, m_tmp, m_data, lsl #24

        tmp_to_a
        update_nzcv
.endm

@ Do a DEC on m_data[7:0]
.macro do_dec
        mov m_data, m_data, lsl #24
        subs m_data, m_data, #(1 << 24) @ dec, update ARM flags
        mov m_data, m_data, lsr #24
        update_nz
.endm

@ Do an INC on m_data[7:0]
.macro do_inc
        mov m_data, m_data, lsl #24
        adds m_data, m_data, #(1 << 24) @ inc, update ARM flags
        mov m_data, m_data, lsr #24
        update_nz
.endm


        .global op_61
op_61: @ ADC ($FF,X)
        memr_addr_mode_indx
        do_adc
        op_end 6

        .global op_65
op_65: @ ADC $FF
        memr_addr_mode_zp
        do_adc
        op_end 3

        .global op_69
op_69:  @ ADC #$FF
        memr_pc_arg8
        do_adc
        op_end 2

        .global op_6d
op_6d: @ ADC $FFFF
        memr_addr_mode_abs
        do_adc
        op_end 4

        .global op_71
op_71: @ ADC ($FF),Y
        memr_addr_mode_indy     @ this increments m_t on page wraps
        do_adc
        op_end 5

        .global op_75
op_75: @ ADC $FF,X
        memr_addr_mode_zpx
        do_adc
        op_end 4

        .global op_79
op_79: @ ADC $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        do_adc
        op_end 4

        .global op_7d
op_7d: @ ADC $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        do_adc
        op_end 4

        .global op_88
op_88: @ DEY
        y_to_tmp
        subs m_tmp, m_tmp, #(1<<24) @ dec Y, update ARM flags
        tmp_to_y
        update_nz                   @ update 6502 flags N and Z
        op_end 2

        .global op_c6
op_c6: @ DEC $FF
        memr_addr_mode_zp
        do_dec
        memw_zp
        op_end 5

        .global op_c8
op_c8:  @ INY
        y_to_tmp
        adds m_tmp, m_tmp, #(1<<24) @ inc Y, update ARM flags
        tmp_to_y
        update_nz                   @ update 6502 flags N and Z
        op_end 2

        .global op_ca
op_ca: @ DEX
        x_to_tmp
        subs m_tmp, m_tmp, #(1<<24) @ dec X, update ARM flags
        tmp_to_x
        update_nz                   @ update 6502 flags N and Z
        op_end 2

        .global op_ce
op_ce: @ DEC $FFFF
        memr_addr_mode_abs
        do_dec
        memw_data_to_addr
        op_end 6

        .global op_d6
op_d6: @ DEC $FF,X
        memr_addr_mode_zpx
        do_dec
        memw_zp
        op_end 6

        .global op_de
op_de: @ DEC $FFFF,X
        memr_addr_mode_absx0    @ no extra cycles on page wraps
        do_dec
        memw_data_to_addr
        op_end 7

        .global op_e1
op_e1: @ SBC ($FF,X)
        memr_addr_mode_indx
        do_sbc
        op_end 6

        .global op_e8
op_e8:  @ INX
        x_to_tmp
        adds m_tmp, m_tmp, #(1<<24) @ inc X, update ARM flags
        tmp_to_x
        update_nz                   @ update 6502 flags N and Z
        op_end 2

        .global op_e5
op_e5: @ SBC $FF
        memr_addr_mode_zp
        do_sbc
        op_end 3

        .global op_e6
op_e6: @ INC $FF
        memr_addr_mode_zp
        do_inc
        memw_zp
        op_end 5

        .global op_e9
op_e9: @ SBC #$FF
        memr_pc_arg8
        do_sbc
        op_end 2

        .global op_ed
op_ed: @ SBC $FFFF
        memr_addr_mode_abs
        do_sbc
        op_end 4

        .global op_ee
op_ee: @ INC $FFFF
        memr_addr_mode_abs
        do_inc
        memw_data_to_addr
        op_end 6

        .global op_f1
op_f1: @ SBC ($FF),Y
        memr_addr_mode_indy     @ this increments m_t on page wraps
        do_sbc
        op_end 5

        .global op_f5
op_f5: @ SBC $FF,X
        memr_addr_mode_zpx
        do_sbc
        op_end 4

        .global op_f6
op_f6: @ INC $FF,X
        memr_addr_mode_zpx
        do_inc
        memw_zp
        op_end 6

        .global op_f9
op_f9: @ SBC $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        do_sbc
        op_end 4

        .global op_fd
op_fd: @ SBC $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        do_sbc
        op_end 4

        .global op_fe
op_fe: @ INC $FFFF,X
        memr_addr_mode_absx0    @ no extra cycles on page wraps
        do_inc
        memw_data_to_addr
        op_end 7
