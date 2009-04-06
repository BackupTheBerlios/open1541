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

@ Do a branch instruction the argument is fetched here,
@ the timer is also updated here.
.macro do_branch
        memr_pc_arg8                @ get argument
        and m_tmp, m_pc, #0xff00    @ remember page before branch
        mov m_data, m_data, lsl #24 @ use asr below to get a real signed value
        add m_pc, m_pc, m_data, asr #24 @ branch

        and m_data, m_pc, #0xff00   @ get page after branch
        cmp m_data, m_tmp
        addne m_t, m_t, #1          @ extra cycle for page crossing
        op_end 3
.endm

        .global op_10
op_10:  @ BPL
        tst m_flags, #MOS6502_N @ check if emulated N bit is set
        bne no_branch           @ set => no branch
        do_branch

        .global op_30
op_30:  @ BMI
        tst m_flags, #MOS6502_N @ check if emulated N bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_50
op_50:  @ BVC
        tst m_flags, #MOS6502_V @ check if emulated V bit is set
        bne no_branch           @ set => no branch
        do_branch

        .global op_70
op_70:  @ BVS
        tst m_flags, #MOS6502_V @ check if emulated V bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_90
op_90:  @ BCC
        tst m_flags, #MOS6502_C @ check if emulated C bit is set
        bne no_branch           @ set => no branch
        do_branch

        .global op_b0
op_b0:  @ BCS
        tst m_flags, #MOS6502_C @ check if emulated C bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_d0
op_d0:  @ BNE
        tst m_flags, #MOS6502_Z @ check if emulated Z bit is set
        bne no_branch           @ set => no branch
        do_branch

no_branch:
        add     m_pc, m_pc, #1
        op_end 2

        .global op_f0
op_f0:  @ BEQ
        tst m_flags, #MOS6502_Z @ check if emulated Z bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_4c
op_4c:  @ JMP abs
        memr_pc_arg16
        mov     m_pc, m_addr
        pc_client_to_host
        op_end 3
