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

@ Do an ORA with m_data[7:0]
.macro do_ora
        a_to_tmp
        orrs m_tmp, m_tmp, m_data, lsl #24
        tmp_to_a
        update_nz               @ update 6502 flags N and Z
.endm

@ Do an AND with m_data[7:0]
.macro do_and
        a_to_tmp
        ands m_tmp, m_tmp, m_data, lsl #24
        tmp_to_a
        update_nz               @ update 6502 flags N and Z
.endm

@ Do an EOR with m_data[7:0]
.macro do_eor
        a_to_tmp
        eors m_tmp, m_tmp, m_data, lsl #24
        tmp_to_a
        update_nz               @ update 6502 flags N and Z
.endm

@ Do an ASL on m_data[7:0]
.macro do_asl
        movs    m_data, m_data, lsl #25
        mov     m_data, m_data, lsr #24
        update_nzc
.endm

@ Do an LSR on m_data[7:0]
.macro do_lsr
        movs    m_data, m_data, lsr #1
        update_nzc              @ N will always be 0
.endm

@ Do a ROL on m_data[7:0]
@ This does not clear bit 8 of m_data, this should disappear when storing
@ the byte
.macro do_rol
        movs    m_tmp, m_flags, lsl #3     @ set ARM C from 6502 C
        adc     m_data, m_data, m_data  @ ROL
        movs    m_tmp, m_data, lsl #24  @ to update flags
        update_nzc
.endm

@ Do a ROR on m_data[7:0]
.macro do_ror
        movs    m_tmp, m_flags, lsl #3     @ set ARM C from 6502 C
        orrcs   m_data, m_data, #(1 << 8)
        movs    m_data, m_data, lsr #1  @ ROR

        @ update flags
        bic     m_flags, m_flags, #(MOS6502_N | MOS6502_Z | MOS6502_C)
        orrcs   m_flags, m_flags, #MOS6502_C
        orreq   m_flags, m_flags, #MOS6502_Z
        tst     m_data, #(1 << 7)
        orrne   m_flags, m_flags, #MOS6502_N
.endm

        .global op_01
op_01: @ ORA ($FF,X)
        memr_addr_mode_indx
        do_ora
op_end_6:
        op_end 6

        .global op_05
op_05: @ ORA $FF
        memr_addr_mode_zp
        do_ora
        op_end 3

        .global op_06
op_06: @ ASL $FF
        memr_addr_mode_zp
        do_asl
        memw_zp
        op_end 5

        .global op_09
op_09: @ ORA #$FF
        memr_pc_arg8
        do_ora
        op_end 2

        .global op_0a
op_0a: @ ASL A
        a_to_data_low
        do_asl
        data_low_to_a
        op_end 2

        .global op_0d
op_0d: @ ORA $FFFF
        memr_addr_mode_abs
        do_ora
        op_end 4

        .global op_0e
op_0e: @ ASL $FFFF
        memr_addr_mode_abs
        do_asl
        memw_data_to_addr
op_end_7:
        op_end 7

        .global op_11
op_11: @ ORA ($FF),Y
        memr_addr_mode_indy     @ this increments m_t on page wraps
        do_ora
        op_end 5

        .global op_15
op_15: @ ORA $FF,X
        memr_addr_mode_zpx
        do_ora
        op_end 4

        .global op_16
op_16: @ ASL $FF,X
        memr_addr_mode_zpx
        do_asl
        memw_zp
        b op_end_6            @ no macro here to save some memory

        .global op_19
op_19: @ ORA $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        do_ora
        op_end 4

        .global op_1d
op_1d: @ ORA $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        do_ora
        op_end 4

        .global op_1e
op_1e: @ ASL $FFFF,X
        memr_addr_mode_absx0    @ no extra cycles on page wraps
        do_asl
        memw_data_to_addr
        b op_end_7            @ no macro here to save some memory

        .global op_21
op_21: @ AND ($FF,X)
        memr_addr_mode_indx
        do_and
        b op_end_6

        .global op_25
op_25: @ AND $FF
        memr_addr_mode_zp
        do_and
        op_end 3

        .global op_26
op_26: @ ROL $FF
        memr_addr_mode_zp
        do_rol
        memw_zp
        op_end 5

        .global op_29
op_29: @ AND #$FF
        memr_pc_arg8
        do_and
        op_end 2

        .global op_2a
op_2a: @ ROL A
        a_to_data_low
        do_rol
        data_low_to_a
        op_end 2

        .global op_2d
op_2d: @ AND $FFFF
        memr_addr_mode_abs
        do_and
        op_end 4

        .global op_2e
op_2e: @ ROL $FFFF
        memr_addr_mode_abs
        do_rol
        memw_data_to_addr
        op_end 6

        .global op_31
op_31: @ AND ($FF),Y
        memr_addr_mode_indy     @ this increments m_t on page wraps
        do_and
        op_end 5

        .global op_35
op_35: @ AND $FF,X
        memr_addr_mode_zpx
        do_and
        op_end 4

        .global op_36
op_36: @ ROL $FF,X
        memr_addr_mode_zpx
        do_rol
        memw_zp
        b op_end_6

        .global op_39
op_39: @ AND $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        do_and
        op_end 4

        .global op_3d
op_3d: @ AND $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        do_and
        op_end 4

        .global op_3e
op_3e: @ ROL $FFFF,X
        memr_addr_mode_absx0    @ no extra cycles on page wraps
        do_rol
        memw_data_to_addr
        b op_end_7            @ no macro here to save some memory

        .global op_41
op_41: @ EOR ($FF,X)
        memr_addr_mode_indx
        do_eor
        b op_end_6

        .global op_45
op_45: @ EOR $FF
        memr_addr_mode_zp
        do_eor
        op_end 3

        .global op_46
op_46: @ LSR $FF
        memr_addr_mode_zp
        do_lsr
        memw_zp
        op_end 5

        .global op_49
op_49: @ EOR #$FF
        memr_pc_arg8
        do_eor
        op_end 2

        .global op_4a
op_4a: @ LSR A
        a_to_data_low
        do_lsr
        data_low_to_a
        op_end 2

        .global op_4d
op_4d: @ EOR $FFFF
        memr_addr_mode_abs
        do_eor
        op_end 4

        .global op_4e
op_4e: @ LSR $FFFF
        memr_addr_mode_abs
        do_lsr
        memw_data_to_addr
        op_end 6

        .global op_51
op_51: @ EOR ($FF),Y
        memr_addr_mode_indy     @ this increments m_t on page wraps
        do_eor
        op_end 5

        .global op_55
op_55: @ EOR $FF,X
        memr_addr_mode_zpx
        do_eor
        op_end 4

        .global op_56
op_56: @ LSR $FF,X
        memr_addr_mode_zpx
        do_lsr
        memw_zp
        b op_end_6

        .global op_59
op_59: @ EOR $FFFF,Y
        memr_addr_mode_absy     @ this increments m_t on page wraps
        do_eor
        op_end 4

        .global op_5d
op_5d: @ EOR $FFFF,X
        memr_addr_mode_absx     @ this increments m_t on page wraps
        do_eor
        op_end 4

        .global op_5e
op_5e: @ LSR $FFFF,X
        memr_addr_mode_absx0    @ no extra cycles on page wraps
        do_lsr
        memw_data_to_addr
        b op_end_7            @ no macro here to save some memory

        .global op_66
op_66: @ ROR $FF
        memr_addr_mode_zp
        do_ror
        memw_zp
        op_end 5

        .global op_6a
op_6a: @ ROR A
        a_to_data_low
        do_ror
        data_low_to_a
        op_end 2

        .global op_6e
op_6e: @ ROR $FFFF
        memr_addr_mode_abs
        do_ror
        memw_data_to_addr
        op_end 6

        .global op_76
op_76: @ ROR $FF,X
        memr_addr_mode_zpx
        do_ror
        memw_zp
        b op_end_6

        .global op_7e
op_7e: @ ROR $FFFF,X
        memr_addr_mode_absx0    @ no extra cycles on page wraps
        do_ror
        memw_data_to_addr
        b op_end_7            @ no macro here to save some memory
