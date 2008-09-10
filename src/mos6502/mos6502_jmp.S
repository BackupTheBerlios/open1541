/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * 6502 processor emulation implemented with some inspiration by code
 * by David Sharp and Neal Tew.
 *
 * This modules contains all branch and jump instructions: 
 * BNE, BEQ, BPL, BMI, BCC, BCS, BVC, BVS, JMP
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
