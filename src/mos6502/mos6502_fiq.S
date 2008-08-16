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

        @ let m_addr point to the table with pointers to readable mem locations
        adr     m_addr, direct_read_addresses

        @ each table entry points to 0x0800 bytes, use the higher bits
        and     m_tmp, m_pc, #0xf800

        @ read pointer to native memory at m_pc to m_addr
        ldr     m_addr, [m_addr, m_tmp, lsr #(11 - 2)]

        @ put lower 11 bits of m_pc into higher part of m_tmp
        mov     m_tmp, m_pc, lsl #(32 - 11)

        @ remember converted pc in m_addr for reading args later
        add     m_addr, m_addr, m_tmp, lsr #(32 - 11)

        @ read opcode
        ldrb    m_tmp, [m_addr]

        @ jump to the opcode address
        ldr pc, [pc, m_tmp, lsl #2]

        nop

        @ the opcode jump table is directly behind our current ARM-PC so we can
        @ use PC + opcode to find the right entry
        .word op_xx, op_01, op_xx, op_xx, op_xx, op_05, op_06, op_xx @ 0
        .word op_xx, op_09, op_0a, op_xx, op_xx, op_0d, op_0e, op_xx
        .word op_10, op_11, op_xx, op_xx, op_xx, op_15, op_16, op_xx @ 1
        .word op_18, op_19, op_xx, op_xx, op_xx, op_1d, op_1e, op_xx
        .word op_xx, op_21, op_xx, op_xx, op_xx, op_25, op_26, op_xx @ 2
        .word op_xx, op_29, op_2a, op_xx, op_xx, op_2d, op_2e, op_xx
        .word op_30, op_xx, op_xx, op_xx, op_xx, op_xx, op_36, op_xx @ 3
        .word op_38, op_xx, op_xx, op_xx, op_xx, op_3d, op_3e, op_xx
        .word op_xx, op_41, op_xx, op_xx, op_xx, op_45, op_46, op_xx @ 4
        .word op_48, op_49, op_4a, op_xx, op_4c, op_4d, op_4e, op_xx
        .word op_50, op_51, op_xx, op_xx, op_xx, op_55, op_56, op_xx @ 5
        .word op_58, op_59, op_xx, op_xx, op_xx, op_5d, op_5e, op_xx
        .word op_xx, op_61, op_xx, op_xx, op_xx, op_65, op_66, op_xx @ 6
        .word op_xx, op_69, op_6a, op_xx, op_xx, op_6d, op_6e, op_xx
        .word op_70, op_71, op_xx, op_xx, op_xx, op_75, op_76, op_xx @ 7
        .word op_78, op_79, op_xx, op_xx, op_xx, op_7d, op_7e, op_xx
        .word op_xx, op_81, op_xx, op_xx, op_84, op_85, op_86, op_xx @ 8
        .word op_88, op_xx, op_8a, op_xx, op_8c, op_8d, op_8e, op_xx
        .word op_90, op_91, op_xx, op_xx, op_94, op_95, op_96, op_xx @ 9
        .word op_98, op_99, op_xx, op_xx, op_xx, op_9d, op_xx, op_xx
        .word op_a0, op_a1, op_a2, op_xx, op_a4, op_a5, op_a6, op_xx @ a
        .word op_a8, op_a9, op_aa, op_xx, op_ac, op_ad, op_ae, op_xx
        .word op_b0, op_b1, op_xx, op_xx, op_b4, op_b5, op_b6, op_xx @ b
        .word op_b8, op_b9, op_xx, op_xx, op_bc, op_bd, op_be, op_xx
        .word op_c0, op_c1, op_xx, op_xx, op_c4, op_c5, op_c6, op_xx @ c
        .word op_c8, op_c9, op_ca, op_xx, op_cc, op_cd, op_ce, op_xx
        .word op_d0, op_d1, op_xx, op_xx, op_xx, op_d5, op_d6, op_xx @ d
        .word op_d8, op_d9, op_xx, op_xx, op_xx, op_dd, op_de, op_xx
        .word op_e0, op_e1, op_xx, op_xx, op_e4, op_e5, op_e6, op_xx @ e
        .word op_e8, op_e9, op_ea, op_xx, op_ec, op_ed, op_ee, op_xx
        .word op_f0, op_f1, op_xx, op_xx, op_xx, op_f5, op_f6, op_xx @ f
        .word op_f8, op_f9, op_xx, op_xx, op_xx, op_fd, op_fe, op_xx

/*******************************************************************************
 * This table points to memory areas for reading instructions from emulated
 * memory directly. It is located in this module to keep its address close to 0,
 * so we can use ADR to get its address relatively to PC.
 *
 * This table is not used to read data, see mos6502_mem.S instead.
 *
 * Each 0x0800 = (1 << 11) = 2048 bytes block has one pointer,
 *
 * Currently the emulated RAM can be read every 2 kBytes. This must be corrected
 * later to meet the real 1541 memory map.
 *
 ******************************************************************************/
        nop @ use more or less NOPs to fix the distance to ADR
        nop
        .global direct_read_addresses
direct_read_addresses:
        .word c1541_ram, c1541_ram, c1541_ram, c1541_ram   @ 0x0000
        .word c1541_ram, c1541_ram, c1541_ram, c1541_ram   @ 0x2000
        .word c1541_ram, c1541_ram, c1541_ram, c1541_ram   @ 0x4000
        .word c1541_ram, c1541_ram, c1541_ram, c1541_ram   @ 0x6000
        .word c1541_ram, c1541_ram, c1541_ram, c1541_ram   @ 0x8000
        .word c1541_ram, c1541_ram, c1541_ram, c1541_ram   @ 0xa000
        .word c1541_ram, c1541_ram, c1541_ram, c1541_ram   @ 0xc000
        .word c1541_ram, c1541_ram, c1541_ram, c1541_ram   @ 0xe000
