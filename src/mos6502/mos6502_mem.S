/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * Macros and functions for memory and I/O accesses
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

#include "mos6502_macros.S"



/*******************************************************************************
 * The mr8_table points to functions responsible for reading a certain
 * memory location. Each 0x0800 = (1 << 11) = 2048 bytes block has one pointer,
 * so specialized functions and memory mirroring will be possible.
 *
 ******************************************************************************/
        .global mr8_table
mr8_table:
        .word mr8_ram, mr_none, mr_via,  mr_none  @ 0x0000
        .word mr_none, mr_none, mr_none, mr_none  @ 0x2000
        .word mr_none, mr_none, mr_none, mr_none  @ 0x4000
        .word mr_none, mr_none, mr_none, mr_none  @ 0x6000
        .word mr_none, mr_none, mr_none, mr_none  @ 0x8000
        .word mr_none, mr_none, mr_none, mr_none  @ 0xa000
        .word mr8_rom, mr8_rom, mr8_rom, mr8_rom  @ 0xc000
        .word mr8_rom, mr8_rom, mr8_rom, mr8_rom  @ 0xe000

/*******************************************************************************
 * The mr8_table points to functions responsible for writing a certain
 * memory location. Each 0x0800 = (1 << 11) = 2048 bytes block has one pointer,
 * so specialized functions and memory mirroring will be possible.
 *
 ******************************************************************************/
        .global memwrite_table
memwrite_table:
    .word memwrite_ram,  memwrite_none, memwrite_via,  memwrite_none @ 0x0000
    .word memwrite_none, memwrite_none, memwrite_none, memwrite_none @ 0x2000
    .word memwrite_none, memwrite_none, memwrite_none, memwrite_none @ 0x4000
    .word memwrite_none, memwrite_none, memwrite_none, memwrite_none @ 0x6000
    .word memwrite_none, memwrite_none, memwrite_none, memwrite_none @ 0x8000
    .word memwrite_none, memwrite_none, memwrite_none, memwrite_none @ 0xa000
    .word memwrite_rom,  memwrite_rom,  memwrite_rom,  memwrite_rom  @ 0xc000
    .word memwrite_rom,  memwrite_rom,  memwrite_rom,  memwrite_rom  @ 0xe000

/*******************************************************************************
 * Read a byte of emulated RAM pointed to by r0. Only the number of bits
 * needed to address mos6502_ramsize bytes are evaluated here.
 * This also changes r1.
 * Return the byte in r0.
 *
 * Return address is taken from r14.
 *
 ******************************************************************************/
mr8_ram:
        ldr r1, =c1541_ram

        @ shift away all forbidden bits
        mov r0, r0, lsl #(32 - mos6502_ramsize_shift)

        @ load the byte, shift back r0 to have the bits in the right positions
        ldrb r0, [r1, r0, lsr #(32 - mos6502_ramsize_shift)]
        mov pc, r14         @ return

mr_none:
mr_via:
mrop_rom:
mr8_rom:
memwrite_ram:
memwrite_none:
memwrite_via:
memwrite_rom:
        mov pc, r14
