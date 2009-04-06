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

.macro do_bit
        bic     m_flags, m_flags, #(MOS6502_N | MOS6502_Z | MOS6502_V)
        tst     m_data, #(1 << 6)
        orrne   m_flags, m_flags, #MOS6502_V
        tst     m_data, #(1 << 7)
        orrne   m_flags, m_flags, #MOS6502_N
        a_to_tmp
        ands    m_tmp, m_tmp, m_data, lsl #24
        orreq   m_flags, m_flags, #MOS6502_Z
.endm

        .global op_18
op_18:  @ CLC
        bic m_flags, #MOS6502_C
        op_end 2

        .global op_24
op_24: @ BIT $FF
        memr_addr_mode_zp
        do_bit
        op_end 3

        .global op_2c
op_2c: @ BIT $FFFF
        memr_addr_mode_abs
        do_bit
        op_end 4

        .global op_38
op_38:  @ SEC
        orr m_flags, m_flags, #MOS6502_C
        op_end 2

        .global op_58
op_58:  @ CLI
        orr m_flags, m_flags, #MOS6502_NI   @ inverted meaning
        op_end 2

        .global op_78
op_78:  @ SEI
        bic m_flags, #MOS6502_NI            @ inverted meaning
        op_end 2

        .global op_b8
op_b8:  @ CLV
        bic m_flags, #MOS6502_V
        op_end 2

        .global op_d8
op_d8:  @ CLD
        bic m_flags, #MOS6502_D
        op_end 2

        .global op_ea
op_ea:  @ NOP
        op_end 2

        .global op_f8
op_f8:  @ SED
        orr m_flags, m_flags, #MOS6502_D
        op_end 2


        .global op_xx
op_00: @ BRK
op_6c: @ JMP ($FFFF)

op_xx:
        op_end 2
