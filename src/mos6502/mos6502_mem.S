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

#include <autoconf.h>
#include "mos6502_macros.S"



/*******************************************************************************
 * memr_table points to functions responsible for reading data at a certain
 * memory location. Each 0x0400 = (1 << 10) = 1024 bytes block has one pointer,
 * so specialized functions and memory mirroring will be possible.
 *
 * This table is not used to read opcodes.
 *
 ******************************************************************************/
        .global memr_table
memr_table:
        .word memr_ram,  memr_ram,  memr_none, memr_none  @ 0x0000
        .word memr_none, memr_none, memr_via1, memr_via2  @ 0x1000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x2000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x3000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x4000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x5000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x6000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x7000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x8000
        .word memr_none, memr_none, memr_none, memr_none  @ 0x9000
        .word memr_none, memr_none, memr_none, memr_none  @ 0xa000
        .word memr_none, memr_none, memr_none, memr_none  @ 0xb000
        .word memr_rom,  memr_rom,  memr_rom,  memr_rom   @ 0xc000
        .word memr_rom,  memr_rom,  memr_rom,  memr_rom   @ 0xd000
        .word memr_rom,  memr_rom,  memr_rom,  memr_rom   @ 0xe000
        .word memr_rom,  memr_rom,  memr_rom,  memr_rom   @ 0xf000

/*******************************************************************************
 * memw_table points to functions responsible for writing data to a certain
 * memory location. Each 0x0400 = (1 << 10) = 1024 bytes block has one pointer,
 * so specialized functions and memory mirroring will be possible.
 *
 ******************************************************************************/
        .global memw_table
memw_table:
        .word memw_ram,  memw_ram,  memw_none, memw_none  @ 0x0000
        .word memw_none, memw_none, memw_via1, memw_via2  @ 0x1000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x2000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x3000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x4000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x5000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x6000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x7000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x8000
        .word memw_none, memw_none, memw_none, memw_none  @ 0x9000
        .word memw_none, memw_none, memw_none, memw_none  @ 0xa000
        .word memw_none, memw_none, memw_none, memw_none  @ 0xb000
        .word memw_none, memw_none, memw_none, memw_none  @ 0xc000
        .word memw_none, memw_none, memw_none, memw_none  @ 0xd000
        .word memw_none, memw_none, memw_none, memw_none  @ 0xe000
        .word memw_none, memw_none, memw_none, memw_none  @ 0xf000

/*******************************************************************************
 * This table points to memory areas for reading instructions from emulated
 * memory directly.
 *
 * This table is not used to read data.
 *
 * Each 0x0800 = (1 << 11) = 2048 bytes block has one pointer,
 *
 * Currently the emulated RAM can be read every 2 kBytes.
 *
 ******************************************************************************/
        .global mem_access_table
mem_access_table:
        .word c1541_ram - 0x0000, c1541_ram - 0x0800 @ 0x0000
        .word c1541_ram - 0x1000, c1541_ram - 0x1800 @ 0x1000
        .word c1541_ram - 0x2000, c1541_ram - 0x2800 @ 0x2000
        .word c1541_ram - 0x3000, c1541_ram - 0x3800 @ 0x3000
        .word c1541_ram - 0x4000, c1541_ram - 0x4800 @ 0x4000
        .word c1541_ram - 0x5000, c1541_ram - 0x5800 @ 0x5000
        .word c1541_ram - 0x6000, c1541_ram - 0x6800 @ 0x6000
        .word c1541_ram - 0x7000, c1541_ram - 0x7800 @ 0x7000
        .word c1541_ram - 0x8000, c1541_ram - 0x8800 @ 0x8000
        .word c1541_ram - 0x9000, c1541_ram - 0x9800 @ 0x9000
        .word c1541_ram - 0xa000, c1541_ram - 0xa800 @ 0xa000
        .word c1541_ram - 0xb000, c1541_ram - 0xb800 @ 0xb000
        .word ROM_IMAGE - 0xc000, ROM_IMAGE - 0xc000 @ 0xc000
        .word ROM_IMAGE - 0xc000, ROM_IMAGE - 0xc000 @ 0xd000
        .word ROM_IMAGE - 0xc000, ROM_IMAGE - 0xc000 @ 0xe000
        .word ROM_IMAGE - 0xc000, ROM_IMAGE - 0xc000 @ 0xf000

/*******************************************************************************
 * Read RAM pointed to by m_addr (client address). Return the result
 * in m_data. Only the number of bits needed to address mos6502_ramsize bytes
 * are evaluated here.
 *
 * In:  m_addr      Client address to be read
 *
 * Out: m_data      The byte
 *      m_tmp       Changed
 *
 *
 ******************************************************************************/
memr_ram:
        ldr m_tmp, =c1541_ram

        @ shift away all forbidden bits (m_data = scratch)
        mov m_data, m_addr, lsl #(32 - mos6502_ramsize_shift)

        @ load byte, shift back m_data to get the bits in the right positions
        ldrb m_data, [m_tmp, m_data, lsr #(32 - mos6502_ramsize_shift)]
        mov pc, lr          @ return

/*******************************************************************************
 * Read ROM pointed to by m_addr (client address). Return the result
 * in m_data. Only the number of bits needed to address mos6502_romsize bytes
 * are evaluated here.
 *
 * In:  m_addr      Client address to be read
 *
 * Out: m_data      The byte
 *      m_tmp       Changed
 *
 *
 ******************************************************************************/
memr_rom:
        ldr m_tmp, =ROM_IMAGE

        @ shift away all forbidden bits (m_data = scratch)
        mov m_data, m_addr, lsl #(32 - mos6502_romsize_shift)

        @ load byte, shift back m_data to get the bits in the right positions
        ldrb m_data, [m_tmp, m_data, lsr #(32 - mos6502_romsize_shift)]
        mov pc, lr          @ return

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
        mov m_data, #0xff
        mov pc, lr

memw_none:
        mov pc, lr
