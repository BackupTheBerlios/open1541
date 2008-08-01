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


@ time [us] when the next instruction will start to be executed
m_t     .req    r8

@ the contents of the 6502 A register in bits 24..31
m_a     .req    r9

@ the contents of the 6502 X register in bits 24..31
m_x     .req    r10

@ the contents of the 6502 Y register in bits 24..31
m_y     .req    r11

@ This register contains the processor status flags and the PC
@ NZCF are kept in the same order and at the same position as in ARM,
@ so they simply can be copied.
@ The bits are:
@ NZCV0000 DI0000Sx PPPPPPPP PPPPPPPP
@ P = pc
@ x = kept for overflow, don't use
@ 0 = reserved
@ S = single step mode, for emulation tests
@
m_pc    .req    r12

@ Processor flags specific to 6502 implementation
MOS6502_N   = (1 << 31) @ must be same as in ARM
MOS6502_Z   = (1 << 30) @ must be same as in ARM
MOS6502_C   = (1 << 29) @ must be same as in ARM
MOS6502_V   = (1 << 28) @ must be same as in ARM
MOS6502_D   = (1 << 23)
MOS6502_I   = (1 << 22)

MOS6502_S   = (1 << 23)

@ our device has 2 kByte of RAM
mos6502_ramsize_shift =   11
mos6502_ramsize       =   (1 << mos6502_ramsize_shift)

/*******************************************************************************
 * Load r0-r2 and lr from stack and return from FIQ.
 *
 ******************************************************************************/
.macro ret_fiq
        ldmfd sp!, {r0 - r2, lr}
        subs pc, lr, #4      @ the magic rti instruction
.endm

/*******************************************************************************
 * Read the memory pointed to by r0. Return the result in r0.
 * This also changes r1, r2 and lr.
 *
 ******************************************************************************/
.macro  mr_r0
        ldr r2, =mr8_table

        @ each table entry points to 0x0800 bytes, use the higher bits
        and r1, r0, #0xf800

        @ prepare link register, will return 2 instructions behind this
        mov lr, pc

        @ jump to the right handler
        ldr pc, [r2, r1, lsr #(11 - 2)]
.endm

/*******************************************************************************
 * Read one byte argument behind m_pc. Return the result in r0.
 * This macros uses r2 which must point to the opcode in the native memory,
 * so it reads *(pc + 1)
 *
 ******************************************************************************/
.macro  mr_pc_arg8
        ldrb r0, [r2, #1]
.endm

/*******************************************************************************
 * Read a two byte argument behind m_pc. Return the result in r0.
 * This macros uses r2 which must point to the opcode in the native memory,
 * so it reads *(pc + 1) | (*(pc + 2) << 8).
 *
 * r1 will be changed here.
 *
 ******************************************************************************/
.macro  mr_pc_arg16
        ldrb r0, [r2, #1]
        ldrb r1, [r2, #2]
        orr r0, r0, r1, lsl #8
.endm

/*******************************************************************************
 * 1. Read one byte argument behind m_pc.
 * 2. Then read the byte pointed to by the byte read at step 1
 * Return the result in r0.
 * This also changes r1, r2 and lr.
 *
 ******************************************************************************/
.macro  mr_addr_mode_zp
        mr_pc_arg8

        @ now r0 contains the zp address, read a byte from there
        ldr r1, =c1541_ram

        @ load the byte
        ldrb r0, [r1, r0]
.endm
