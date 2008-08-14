/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * Functions for memory and I/O access
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
 * memr_table points to functions responsible for reading data at a certain
 * memory location. Each 0x0800 = (1 << 11) = 2048 bytes block has one pointer,
 * so specialized functions and memory mirroring will be possible.
 *
 * This table is not used to read opcodes, see mos6502_fiq.S instead.
 *
 ******************************************************************************/
        .global memr_table
memr_table:
        .word memr_ram,  memr_none, memr_via,  memr_none  @ 0x0000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x2000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x4000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x6000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x8000
        .word memr_none, memr_none, memr_none, memr_none  @ 0xa000
        .word memr_rom,  memr_rom,  memr_rom,  memr_rom   @ 0xc000
        .word memr_rom,  memr_rom,  memr_rom,  memr_rom   @ 0xe000

/*******************************************************************************
 * memw_table points to functions responsible for writing data to a certain
 * memory location. Each 0x0800 = (1 << 11) = 2048 bytes block has one pointer,
 * so specialized functions and memory mirroring will be possible.
 *
 ******************************************************************************/
        .global memw_table
memw_table:
        .word memw_ram,  memw_none, memw_via,  memw_none  @ 0x0000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x2000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x4000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x6000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x8000
        .word memw_none, memw_none, memw_none, memw_none  @ 0xa000
        .word memw_none, memw_none, memw_none, memw_none  @ 0xc000
        .word memw_none, memw_none, memw_none, memw_none  @ 0xe000

/*******************************************************************************
 * Read RAM pointed to by m_addr (client address). Return the result
 * in m_data. Only the number of bits needed to address mos6502_ramsize bytes
 * are evaluated here.
 *
 * In:  m_addr      Client address to be read
 *
 * Out: m_data      The byte
 *      m_tmp       Changed
 *      lr          Changed
 *
 *
 ******************************************************************************/
memr_ram:
        ldr m_tmp, =c1541_ram

        @ shift away all forbidden bits (m_data = scratch)
        mov m_data, m_addr, lsl #(32 - mos6502_ramsize_shift)

        @ load the byte, shift back r0 to have the bits in the right positions
        ldrb m_data, [m_tmp, m_data, lsr #(32 - mos6502_ramsize_shift)]
        mov pc, r14         @ return

/*******************************************************************************
 * Write byte m_data to the client RAM m_addr.
 *
 * In:  m_addr      Client address
 *      m_data      The byte to be written
 *
 * Out: m_addr      Changed (!!!)
 *      m_tmp       Changed
 *
 ******************************************************************************/
memw_ram:
        ldr     m_tmp, =c1541_ram

        @ shift away all forbidden bits
        mov     m_addr, m_addr, lsl #(32 - mos6502_ramsize_shift)

        @ store the byte, shift back the bits to original real position
        strb    m_data, [m_tmp, m_addr, lsr #(32 - mos6502_ramsize_shift)] 
        mov     pc, lr                  @ return

memr_none:
memr_via:
memr_rom:
        mov m_data, #0xff
        mov pc, lr

memw_none:
memw_via:
        mov pc, lr
