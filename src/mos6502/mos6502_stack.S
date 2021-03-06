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
        tst     m_flags, #MOS6502_NI
        orreq   m_data, m_data, #(1 << 2)   @ inverted meaning!
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
        orreq   m_flags, m_flags, #MOS6502_NI   @ inverted meaning!
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
        op_end 3


        .global op_20
op_20: @ JSR $FFFF
        memr_pc_arg16

        pc_host_to_client m_pc

        @ get SP
        sp_to_tmp

        @ PUSH high byte
        @ PC points to next op, on stack there must be (next - 1)
        sub     m_data, m_pc, #1
        mov     m_data, m_data, lsr #8
        ldr     lr, =(c1541_ram + 0x100)
        strb    m_data, [lr, m_tmp]

        @ dec SP
        sub     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PUSH low byte
        @ PC points to next op, on stack there must be (next - 1)
        sub     m_data, m_pc, #1            @ OPTIMIZE ME
        strb    m_data, [lr, m_tmp]

        @ dec SP, we'll only store one byte so it wraps automatically
        sub     m_tmp, m_tmp, #1

        @ save SP
        tmp_to_sp

        mov     m_pc, m_addr
        pc_client_to_host

        op_end 6


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
        op_end 4


        .global op_40
op_40: @ RTI
        @ get SP
        sp_to_tmp

        @ remove old 6502 flags
        bic     m_flags, #MOS6502_CPU_FLAGS_MASK

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
        op_end 6


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
        op_end 3


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
        add     m_pc, m_pc, #1
        pc_client_to_host
        op_end 6


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
        op_end 4


        .global op_ba
op_ba: @ TSX
        @ get SP
        sp_to_data
        data_low_to_x
        movs m_data, m_data, lsl #24
        update_nz
        op_end 2


        .global op_9a
op_9a: @ TXS
        x_to_data_low
        data_to_sp
        op_end 2

/*******************************************************************************
 * Do what has to be done to execute an IRQ.
 *
 ******************************************************************************/
        .global mos6502_do_irq
mos6502_do_irq:
        pc_host_to_client m_pc

        @ get SP
        sp_to_tmp

        @ PUSH high byte
        mov     m_data, m_pc, lsr #8
        ldr     lr, =(c1541_ram + 0x100)
        strb    m_data, [lr, m_tmp]

        @ dec SP
        sub     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PUSH low byte
        strb    m_pc, [lr, m_tmp]

        @ dec SP
        sub     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff

        @ PUSH P
        flags_to_data
        @ PHP does always push B=1
@@@@@@        orr     m_data, m_data, #(1 << 4)

        ldr     m_addr, =(c1541_ram + 0x100)
        strb    m_data, [lr, m_tmp]

        @ dec SP, we'll only store one byte so it wraps automatically
        sub     m_tmp, m_tmp, #1

        @ save SP
        tmp_to_sp

        @ read IRQ vector
        mov     m_addr, #0xff00
        add     m_addr, m_addr, #0xfe
        memr_addr
        mov     m_pc, m_data
        add     m_addr, m_addr, #1
        memr_addr
        orr     m_pc, m_data, lsl #8
        pc_client_to_host

        @ this took 7 cycles (todo: 8 under certain conditions)
        add     m_t, m_t, #7

        @ set IRQ flag and fetch an opcode
        bic     m_flags, m_flags, #MOS6502_NI   @ inverted meaning
        b       mos6502_fetch
