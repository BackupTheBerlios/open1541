/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * 6502 processor emulation implemented with some inspiration by code
 * by David Sharp and Neal Tew.
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

#include <mos6502_macros.S>

/*******************************************************************************
 * Execute a single instruction on the emulated 6502 processor.
 * This code must be place at the FIQ vector.
 *
 ******************************************************************************/
        stmfd sp!, {r0 - r2, lr}

        ldr r2, =mrop_table

        @ each table entry points to 0x0800 bytes, use the higher bits
        and r1, m_pc, #0xf800

        @ prepare link register, will return 2 instructions behind this
        mov lr, pc

        @ jump to the right opcode reader
        @ read emulated memory at m_pc to r0
        @ r2 will point to the native memory at the opcode on return
        ldr pc, [r2, r1, lsr #(11 - 2)]

        @ todo: Check if it is faster to jump to the opcode handlers
        @       directly from the opcode readers
        @ jump to the opcode address
        ldr pc, [pc, r0, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ 0
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_10, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ 1
        .word op_18, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ 2
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_30, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ 3
        .word op_38, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ 4
        .word op_xx, op_xx, op_xx, op_xx, op_4c, op_xx, op_xx, op_xx
        .word op_50, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ 5
        .word op_58, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ 6
        .word op_xx, op_69, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_70, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ 7
        .word op_78, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ 8
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_90, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ 9
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_a0, op_xx, op_a2, op_xx, op_xx, op_a5, op_a6, op_xx @ a
        .word op_xx, op_a9, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_b0, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ b
        .word op_b8, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ c
        .word op_c8, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_d0, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ d
        .word op_d8, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ e
        .word op_e8, op_xx, op_ea, op_xx, op_xx, op_xx, op_xx, op_xx
        .word op_f0, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx @ f
        .word op_f8, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx, op_xx
