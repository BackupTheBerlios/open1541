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
 * This macros uses r2 which must point to the opcode in the native memory.
 * It reads *(pc + 1)
 *
 ******************************************************************************/
.macro  mr_pc_arg8
        ldrb r0, [r2, #1]
.endm

/*******************************************************************************
 * Read a two byte argument behind m_pc. Return the result in r0[0..15].
 * This macros uses r2 which must point to the opcode in the native memory.
 * It reads *(pc + 1) | (*(pc + 2) << 8).
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
 * This macros uses r2 which must point to the opcode in the native memory.
 * Return the result in r0.
 * This also changes r1.
 *
 ******************************************************************************/
.macro  mr_addr_mode_zp
        mr_pc_arg8

        @ now r0 contains the zp address, read a byte from there
        ldr r1, =c1541_ram

        @ load the byte
        ldrb r0, [r1, r0]
.endm

/*******************************************************************************
 * 1. Read one byte argument behind m_pc.
 * 2. Add X to this value, use only lower 8 bits of the result
 * 3. Then read the byte at this calculated address
 * This macros uses r2 which must point to the opcode in the native memory.
 * Return the result in r0.
 * This also changes r1, r2 and lr.
 *
 ******************************************************************************/
.macro  mr_addr_mode_zpx
        mr_pc_arg8

        @ now r0[0..7] contains the zp address, add it shifted to X into r0[24..31]
        add r0, m_x, r0, lsl #24

        @ read a byte from there, shift back the address bits to 0..7
        ldr r1, =c1541_ram
        ldrb r0, [r1, r0, lsr #24]
.endm

/*******************************************************************************
 * 1. Read two bytes argument behind m_pc.
 * 2. Then read the byte pointed to by the byte read at step 1
 * This macros uses r2 which must point to the opcode in the native memory.
 * Return the result in r0.
 * This also changes r1, r2 and lr.
 *
 ******************************************************************************/
.macro  mr_addr_mode_abs
        mr_pc_arg16

        @ now r0 contains the address, read a byte from there
        mr_r0
.endm

/*******************************************************************************
 * 1. Read two bytes argument behind m_pc.
 * 2. Add X to this value, use only lower 16 bits of the result
 * 3. Then read the byte at this calculated address
 * This macros uses r2 which must point to the opcode in the native memory.
 * One penalty cycle is added here if the page wraps.
 * Return the result in r0.
 * This also changes r1, r2 and lr.
 *
 ******************************************************************************/
.macro  mr_addr_mode_absx
        mr_pc_arg16

        @ now r0[0..15] contains the address, remember the high-byte in r2[0..7]
        mov r2, r0, lsr #8

        @ add X to address and remove overflow bit
        add r0, r0, m_x, lsr #24
        bic r0, r0, #(1 << 16)

        @ check if high-byte remained same
        teq r2, r0, lsr #8

        @ if not, add one cycle
        addne m_t, m_t, #1

        @ now r0 contains the address, read a byte from there
        mr_r0
.endm

/*******************************************************************************
 * 1. Read two bytes argument behind m_pc.
 * 2. Add Y to this value, use only lower 16 bits of the result
 * 3. Then read the byte at this calculated address
 * This macros uses r2 which must point to the opcode in the native memory.
 * One penalty cycle is added here if the page wraps.
 * Return the result in r0.
 * This also changes r1, r2 and lr.
 *
 ******************************************************************************/
.macro  mr_addr_mode_absy
        mr_pc_arg16

        @ now r0[0..15] contains the address, remember the high-byte in r2[0..7]
        mov r2, r0, lsr #8

        @ add Y to address and remove overflow bit
        add r0, r0, m_y, lsr #24
        bic r0, r0, #(1 << 16)

        @ check if high-byte remained same
        teq r2, r0, lsr #8

        @ if not, add one cycle
        addne m_t, m_t, #1

        @ now r0 contains the address, read a byte from there
        mr_r0
.endm

/*******************************************************************************
 * Adressing mode (Indirect,X)
 * 1. Read one byte argument behind m_pc.
 * 2. Add X to this value, use only lower 8 bits of the result
 * 3. Then read two bytes at this calculated address, that's the address we need
 * 4. Load the value from there
 * Return the result in r0.
 * This also changes r1, r2 and lr.
 *
 ******************************************************************************/
.macro  mr_addr_mode_indx
        mr_pc_arg8

        @ now r0[0..7] contains the zp address, add it to X into r0[24..31]
        add     r0, m_x, r0, lsl #24

        @ load a byte from there, that's the low byte of the address
        ldr     r2, =c1541_ram
        ldrb    r1, [r2, r0, lsr #24]

        @ the next one is the high byte, merge them into r0
        add     r0, r0, #(1 << 24)
        ldrb    r0, [r2, r0, lsr #24]
        orr     r0, r1, r0, lsl #8

        @ now r0 contains the address, read a byte from there
        mr_r0
.endm

/*******************************************************************************
 * Adressing mode (Indirect),Y
 * 1. Read one byte argument behind m_pc.
 * 2. Then read two bytes at this, that's the base address
 * 3. Add Y to this base address, use only lower 16 bits of the result
 * 4. Load the value from there
 * One penalty cycle is added here if the page wraps.
 * Return the result in r0.
 * This also changes r1, r2 and lr.
 *
 ******************************************************************************/
.macro  mr_addr_mode_indy
        mr_pc_arg8

        @ now r0[0..7] contains the zp address
        @ load a byte from there, that's the low byte of the address
        ldr     r2, =c1541_ram
        ldrb    r1, [r2, r0]

        @ the next one is the high byte, merge them into r0
        add     r0, r0, #1
        bic     r0, r0, #(1 << 8)
        ldrb    r0, [r2, r0]
        orr     r0, r1, r0, lsl #8

        @ remember high-byte of address
        mov     r2, r0, lsr #24

        @ add Y to it, use 16 bits only
        add     r0, r0, m_y, lsr #24
        bic     r0, r0, #(1 << 16)

        @ check if high-byte remained same
        teq     r2, r0, lsr #8

        @ if not, add one cycle
        addne m_t, m_t, #1

        @ now r0 contains the address, read a byte from there
        mr_r0
.endm

/*******************************************************************************
 * Increment PC by the given value.
 ******************************************************************************/
.macro inc_pc num
.ifne \num
        add m_pc, m_pc, #\num
        @ todo: Delete bit 16 at a convinient place. This may be set if the PC
        @ wraps from 0xffff to 0, Don't wanna spend a cycle here for this
        @ unlikely case
.endif
.endm

/*******************************************************************************
 * Set the CPU emulation timer to expire in 'time' microseconds.
 ******************************************************************************/
.macro inc_time time
        @ Ack timer 0 interrupt
        mov r0, #TIR_MR0
        mov r1,     #(T0IR & 0xffff0000)
        orr r1, r1, #(T0IR & 0x0000ffff)
        str r0, [r1]

        @ Set next timer
        add m_t, m_t, #\time
        add r1, r1, #(T0MR0 - T0IR)
        @ do not program the timer match register in single step mode
        tst m_pc, #MOS6502_S
        streq m_t, [r1]
.endm

/*******************************************************************************
 * Increment the PC by the given number,
 * Set the CPU emulation timer to expire in 'time' microseconds,
 * Return from FIQ
 ******************************************************************************/
.macro op_end pc time
        inc_pc \pc
        inc_time \time
        ret_fiq
.endm

/*******************************************************************************
 * Update 6502 flags N and Z with flags from ARM
 ******************************************************************************/
.macro update_nz
        bic       m_pc, m_pc, #(MOS6502_N | MOS6502_Z)
        orrmi     m_pc, m_pc, #MOS6502_N
        orreq     m_pc, m_pc, #MOS6502_Z
.endm

/*******************************************************************************
 * Update 6502 flags NZCV with flags from ARM
 ******************************************************************************/
.macro update_nzcv
        mrs r0, cpsr                @ get PSR into r0
        and r0, r0, #0xff000000     @ isolate flags
        bic m_pc, m_pc, #0xff000000 @ clear 6502 flags
        orr m_pc, m_pc, r0          @ copy flags to 6502
.endm
