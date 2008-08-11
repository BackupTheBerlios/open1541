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
        mr_pc_arg8              @ get argument
        inc_pc 2                @ advance the pc as usual
        and r1, m_pc, #0xff00   @ remember page before branch
        mov r0, r0, lsl #24     @ we use asr below to get a real signed value
        add m_pc, m_pc, r0, asr #24 @ branch

        and r0, m_pc, #0xff00   @ get page after branch
        cmp r0, r1
        addne m_t, m_t, #1      @ use an extra cycle for page crossing
        op_end 0 3
.endm

        .global op_10
op_10:  @ BPL
        tst m_pc, #MOS6502_N    @ check if emulated N bit is set
        bne no_branch           @ set => no branch
        do_branch

        .global op_30
op_30:  @ BMI
        tst m_pc, #MOS6502_N    @ check if emulated N bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_50
op_50:  @ BVC
        tst m_pc, #MOS6502_V    @ check if emulated V bit is set
        bne no_branch           @ set => no branch
        do_branch

        .global op_70
op_70:  @ BVS
        tst m_pc, #MOS6502_V    @ check if emulated V bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_90
op_90:  @ BCC
        tst m_pc, #MOS6502_C    @ check if emulated C bit is set
        bne no_branch           @ set => no branch
        do_branch

        .global op_b0
op_b0:  @ BCS
        tst m_pc, #MOS6502_C    @ check if emulated C bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_d0
op_d0:  @ BNE
        tst m_pc, #MOS6502_Z    @ check if emulated Z bit is set
        bne no_branch           @ set => no branch
        do_branch

no_branch:
        op_end 2 2

        .global op_f0
op_f0:  @ BEQ
        tst m_pc, #MOS6502_Z    @ check if emulated Z bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_4c
op_4c:  @ JMP abs
        mr_pc_arg16
        mov m_pc, m_pc, lsr #16     @ remove old PC
        add m_pc, r0, m_pc, lsl #16 @ set new PC
        op_end 0 3

