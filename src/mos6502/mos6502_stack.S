/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
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
 */

#include <lpc213x.h>
#include "mos6502_macros.S"

@ put the emulated processor flags into m_data in 6502 order
.macro flags_to_data
        @ That's stupid, can't we do this easier?
        mov     m_data, #(1 << 5)
        tst     m_flags, #MOS6502_N
        orrne   m_data, m_data, #(1 << 7)
        tst     m_flags, #MOS6502_V
        orrne   m_data, m_data, #(1 << 6)
        tst     m_flags, #MOS6502_D
        orrne   m_data, m_data, #(1 << 3)
        tst     m_flags, #MOS6502_I
        orrne   m_data, m_data, #(1 << 2)
        tst     m_flags, #MOS6502_Z
        orrne   m_data, m_data, #(1 << 1)
        tst     m_flags, #MOS6502_C
        orrne   m_data, m_data, #(1 << 0)
.endm

@ get the emulated processor flags from m_data in 6502 order
.macro data_to_flags
        @ That's stupid, can't we do this easier?
        bic     m_flags, m_flags, #(0xff << 24)
        tst     m_data, #(1 << 7)
        orrne   m_flags, m_flags, #MOS6502_N
        tst     m_data, #(1 << 6)
        @ todo: Check what to do here
        @ orrne   m_flags, m_flags, #MOS6502_B
        @ tst     m_data, #(1 << 4)
        orrne   m_flags, m_flags, #MOS6502_V
        tst     m_data, #(1 << 3)
        orrne   m_flags, m_flags, #MOS6502_D
        tst     m_data, #(1 << 2)
        orrne   m_flags, m_flags, #MOS6502_I
        tst     m_data, #(1 << 1)
        orrne   m_flags, m_flags, #MOS6502_Z
        tst     m_data, #(1 << 0)
        orrne   m_flags, m_flags, #MOS6502_C
.endm


        .global op_08
op_08: @ PHP
        flags_to_data
        @ PHP does always push B=1
        orr     m_data, m_data, #(1 << 4)

        @ get SP
        sp_to_tmp

        @ PUSH
        ldr     m_addr, =(c1541_ram + 0x100)
        strb    m_data, [m_addr, m_tmp]

        @ dec SP, we'll only store one byte so it wraps automatically
        sub     m_tmp, m_tmp, #1

        @ save SP
        tmp_to_sp
        op_end 1 3


        .global op_20
op_20: @ JSR $FFFF
        memr_pc_arg16

        pc_host_to_client m_pc

        @ get SP
        sp_to_tmp

        @ PUSH high byte
        @ PC still points to this JSR, on stack there must be (next - 1), so + 2
        add     m_data, m_pc, #2
        mov     m_data, m_data, lsr #8
        ldr     lr, =(c1541_ram + 0x100)
        strb    m_data, [lr, m_tmp]

        @ dec SP
        sub     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PUSH low byte
        @ PC still points to this JSR, on stack there must be (next - 1), so + 2
        add     m_data, m_pc, #2            @ OPTIMIZE ME
        strb    m_data, [lr, m_tmp]

        @ dec SP, we'll only store one byte so it wraps automatically
        sub     m_tmp, m_tmp, #1

        @ save SP
        tmp_to_sp

        mov     m_pc, m_addr
        pc_client_to_host

        op_end 0 6


        .global op_28
op_28: @ PLP
        @ get SP
        sp_to_tmp

        @ inc SP, wrap it
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PULL
        ldr     m_addr, =(c1541_ram + 0x100)
        ldrb    m_data, [m_addr, m_tmp]

        data_to_flags

        @ save SP
        tmp_to_sp
        op_end 1 4


        .global op_40
op_40: @ RTI
        @ get SP
        sp_to_tmp

        @ remove old 6502 flags
        and     m_flags, m_flags, #MOS6502_FLAGS_EMU_MASK

        @ inc SP, wrap it
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PULL flags
        ldr     m_addr, =(c1541_ram + 0x100)
        ldrb    m_data, [m_addr, m_tmp]
        data_to_flags

        @ inc SP, wrap it
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PULL low byte
        ldrb    m_pc, [m_addr, m_tmp]

        @ inc SP, wrap it
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PULL high byte
        ldrb    m_data, [m_addr, m_tmp]
        orr     m_pc, m_pc, m_data, lsl #8

        @ save SP
        tmp_to_sp
        pc_client_to_host
        op_end 0 6


        .global op_48
op_48: @ PHA
        a_to_data_low

        sp_to_tmp

        @ PUSH
        ldr     m_addr, =(c1541_ram + 0x100)
        strb    m_data, [m_addr, m_tmp]

        @ dec SP, we'll only store one byte so it wraps automatically
        sub     m_tmp, m_tmp, #1

        tmp_to_sp
        op_end 1 3


        .global op_60
op_60: @ RTS
        sp_to_tmp

        @ inc SP, wrap it
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PULL low byte, shift PC back
        ldr     m_addr, =(c1541_ram + 0x100)
        ldrb    m_pc, [m_addr, m_tmp]

        @ inc SP, wrap it
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PULL high byte
        ldrb    m_data, [m_addr, m_tmp]
        orr     m_pc, m_pc, m_data, lsl #8

        tmp_to_sp
        pc_client_to_host
        op_end 1 6


        .global op_68
op_68: @ PLA
        @ get SP
        sp_to_tmp

        @ inc SP, wrap it
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PULL
        ldr     m_addr, =(c1541_ram + 0x100)
        ldrb    m_data, [m_addr, m_tmp]
        data_low_to_a

        @ save SP
        tmp_to_sp
        update_nz
        op_end 1 4


        .global op_ba
op_ba: @ TSX
        @ get SP
        sp_to_data
        data_low_to_x
        movs m_data, m_data, lsl #24
        update_nz
        op_end 1 2


        .global op_9a
op_9a: @ TXS
        x_to_data_low
        data_to_sp
        op_end 1 2
