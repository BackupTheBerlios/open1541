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

#ifndef MOS6502_MACROS_H
#define MOS6502_MACROS_H

MACH_DATA_DECLARE = 1
#include <mach_data.S>

@ may be used as scratch register
m_tmp   .req    r0

@ contains the value we are currently working on
@ may be also used as scratch register
m_data  .req    r1

@ contains the address we are currently working on, depending from the
@ context this may be an client (emulated) or a host address
@ may be also used as scratch register
m_addr  .req    r2


@ time [us] when the next instruction will start to be executed
m_t     .req    r8

@ pointer to host memory corresponding to emulated client's PC
@ this pointer is always updated while m_flags gets only updated...
m_pc   .req    r9

@ permanent pointer to mos6502_data
m_pdata .req    r10

@ permanent pointer to timer0 registers
m_ptimer .req   r11

@ This register contains the processor status flags
@ NZCF are kept in the same order and at the same position as in ARM,
@ so they simply can be copied.
@ The bits are:
@ NZCVBDI0 00000PS0 00000sVv 0000000z
@ P = break point hit
@ S = single step mode, for emulation tests
@ 0 = reserved
@
@ IRQ flags (1 = IRQ from this device)
@ v = VIA1 IRQ
@ V = VIA2 IRQ
@ s = SIM IRQ
@
@ VIA helpers:
@ z = VIA1 CA1 low edge detected
@
m_flags    .req    r12

@ Processor flags specific to 6502 implementation
MOS6502_N   = (1 << 31) @ must be same as in ARM
MOS6502_Z   = (1 << 30) @ must be same as in ARM
MOS6502_C   = (1 << 29) @ must be same as in ARM
MOS6502_V   = (1 << 28) @ must be same as in ARM
MOS6502_B   = (1 << 27)
MOS6502_D   = (1 << 26)
MOS6502_NI  = (1 << 25) @ inverted meaning of 6502 I-Flag

MOS6502_P   = (1 << 16) @ stopped because of a break point
MOS6502_S   = (1 << 17) @ single step mode

MOS6502_IRQ_VIA1 = (1 <<  8) @ IRQ from VIA1
MOS6502_IRQ_VIA2 = (1 <<  9) @ IRQ from VIA2
MOS6502_IRQ_SIM  = (1 << 10) @ IRQ from VIA2

// VIA helpers
VIA1_CA1_LOW_EDGE_DETECTED = (1 << 0)


MOS6502_IRQ_MASK = (MOS6502_IRQ_VIA1 | MOS6502_IRQ_VIA2 | MOS6502_IRQ_SIM)

@ This mask leaves only bits used by the emulation
MOS6502_FLAGS_EMU_MASK = 0x00ff0000

@ our client has 2 kByte of RAM
mos6502_ramsize_shift =   11
mos6502_ramsize       =   (1 << mos6502_ramsize_shift)

@ our client has 16 kByte of ROM
mos6502_romsize_shift =   14
mos6502_romsize       =   (1 << mos6502_ramsize_shift)

/*******************************************************************************
 * Macros to load and store data
 *
 ******************************************************************************/

.macro tmp_to_sp
        str m_tmp, [m_pdata, #MOS6502_SP_OFFSET]
.endm

.macro tmp_to_a
        str m_tmp, [m_pdata, #MOS6502_A_OFFSET]
.endm

.macro tmp_to_x
        str m_tmp, [m_pdata, #MOS6502_X_OFFSET]
.endm

.macro tmp_to_y
        str m_tmp, [m_pdata, #MOS6502_Y_OFFSET]
.endm

.macro data_to_sp
        str m_data, [m_pdata, #MOS6502_SP_OFFSET]
.endm

.macro data_to_a
        str m_data, [m_pdata, #MOS6502_A_OFFSET]
.endm

.macro data_to_x
        str m_data, [m_pdata, #MOS6502_X_OFFSET]
.endm

.macro data_to_y
        str m_data, [m_pdata, #MOS6502_Y_OFFSET]
.endm

.macro data_low_to_a
        strb m_data, [m_pdata, #MOS6502_A_OFFSET + 3]
.endm

.macro data_low_to_x
        strb m_data, [m_pdata, #MOS6502_X_OFFSET + 3]
.endm

.macro data_low_to_y
        strb m_data, [m_pdata, #MOS6502_Y_OFFSET + 3]
.endm


.macro sp_to_tmp
        ldr m_tmp, [m_pdata, #MOS6502_SP_OFFSET]
.endm

.macro a_to_tmp
        ldr m_tmp, [m_pdata, #MOS6502_A_OFFSET]
.endm

.macro x_to_tmp
        ldr m_tmp, [m_pdata, #MOS6502_X_OFFSET]
.endm

.macro y_to_tmp
        ldr m_tmp, [m_pdata, #MOS6502_Y_OFFSET]
.endm

.macro sp_to_data
        ldr m_data, [m_pdata, #MOS6502_SP_OFFSET]
.endm

.macro a_to_data
        ldr m_data, [m_pdata, #MOS6502_A_OFFSET]
.endm

.macro x_to_data
        ldr m_data, [m_pdata, #MOS6502_X_OFFSET]
.endm

.macro y_to_data
        ldr m_data, [m_pdata, #MOS6502_Y_OFFSET]
.endm

.macro a_to_data_low
        ldrb m_data, [m_pdata, #MOS6502_A_OFFSET + 3]
.endm

.macro x_to_data_low
        ldrb m_data, [m_pdata, #MOS6502_X_OFFSET + 3]
.endm

.macro y_to_data_low
        ldrb m_data, [m_pdata, #MOS6502_Y_OFFSET + 3]
.endm

/*******************************************************************************
 * Load r0-r2 and lr from stack and return from FIQ.
 *
 ******************************************************************************/
.macro ret_fiq
        ldmfd sp!, {r0 - r2, lr}
        subs pc, lr, #4      @ the magic rti instruction
.endm

/*******************************************************************************
 * Convert m_pc from a client address to a host address,
 * put the result into m_pc.
 *
 * In:  m_pc        Contains a client address (0x0000..0xffff)
 *
 * Out: m_pc        Contains a host address
 *      m_tmp       Changed
 *      m_addr      Changed
 *
 ******************************************************************************/
.macro pc_client_to_host
        @ let m_addr point to the table with pointers to readable mem locations
        ldr     m_addr, =mem_access_table

        @ each table entry points to 0x0800 bytes, use the higher bits
        and     m_tmp, m_pc, #0xf800

        @ read offset from client address to host address for this value of m_pc
        ldr     m_tmp, [m_addr, m_tmp, lsr #(11 - 2)]

        @ remember this offset for converting PC back later
        str     m_tmp, [m_pdata, #MOS6502_PC_OFFSET_OFFSET]

        @ remember converted m_pc
        add     m_pc, m_pc, m_tmp
.endm

/*******************************************************************************
 * Convert m_pc from a host address to client address,
 * put the result into dest.
 *
 * In:  m_pc        Contains a host address
 *
 * Out: dest        Contains a client address (0x0000..0xffff)
 *      m_tmp       Changed
 *
 ******************************************************************************/
.macro pc_host_to_client dest
        @ get the current PC offset
        ldr     m_tmp, [m_pdata, #MOS6502_PC_OFFSET_OFFSET]

        @ convert PC to client address
        sub     \dest, m_pc, m_tmp
.endm

/*******************************************************************************
 * Read the memory pointed to by m_addr (client address). Return the result
 * in m_data.
 *
 * In:  m_addr      Client address to be read
 *
 * Out: m_data      The byte
 *      m_tmp       Changed
 *      lr          Changed
 *
 ******************************************************************************/
.macro  memr_addr
        ldr m_data, =memr_table     @ m_data used as scratch reg

        @ each table entry points to 0x0400 bytes, use the higher bits
        and m_tmp, m_addr, #0xfc00

        @ prepare link register, will return 2 instructions behind this
        mov lr, pc

        @ call the right handler
        ldr pc, [m_data, m_tmp, lsr #(10 - 2)]
.endm

/*******************************************************************************
 * Write byte m_data to the client memory m_addr.
 *
 * In:  m_addr      Client address
 *      m_data      The byte to be written
 *
 * Out:
 *      m_addr      Changed (!!!)
 *      m_tmp       Changed
 *      lr          Changed
 *
 ******************************************************************************/
.macro  memw_data_to_addr
        ldr m_tmp, =memw_table

        @ each table entry points to 0x0400 bytes, use the higher bits
        add m_tmp, m_tmp, m_addr, lsr #(10 - 2)
        bic m_tmp, m_tmp, #3

        @ prepare link register, will return 2 instructions behind this
        mov lr, pc

        @ jump to the right handler
        ldr pc, [m_tmp]
.endm

/*******************************************************************************
 * Read one byte argument at m_pc and increment m_pc.
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_data  The byte
 *
 ******************************************************************************/
.macro  memr_pc_arg8
        ldrb    m_data, [m_pc], #1
.endm

/*******************************************************************************
 * Read a two byte argument behind m_pc and increment m_pc two times.
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_addr  Two bytes behind opcode (little endian [15:0] )
 *      m_tmp   Changed
 *
 *
 ******************************************************************************/
.macro  memr_pc_arg16
        ldrb    m_tmp, [m_pc], #1
        ldrb    m_addr, [m_pc], #1
        orr     m_addr, m_tmp, m_addr, lsl #8
.endm

/*******************************************************************************
 * Zero page addressing mode (read)
 * 1. Read one byte at m_pc, increment m_pc.
 * 2. Then read the byte pointed to by the byte read at step 1
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_addr  Client address of the byte
 *      m_data  The byte
 *      m_tmp   Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_zp
        @ read argument at PC (zeropage address)
        ldrb    m_addr, [m_pc], #1

        @ now m_addr contains the zp address, read a byte from there
        ldr     m_tmp, =c1541_ram
        ldrb    m_data, [m_tmp, m_addr]
.endm

/*******************************************************************************
 * Zero page addressing mode (write)
 * 1. Read one byte at m_pc, increment m_pc.
 * 2. Write the byte from m_dataq[7:0] to the address read at step 1
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *      m_data  Byte to be written
 *
 * Out: m_addr  Client address of the byte
 *      m_tmp   Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_zp
        @ read argument at PC (zeropage address)
        ldrb    m_addr, [m_pc], #1

        @ store data byte to that address into RAM
        ldr     m_tmp, =c1541_ram
        strb    m_data, [m_tmp, m_addr]
.endm

/*******************************************************************************
 * Zeropage,X addressing mode (read)
 * 1. Read one byte at m_pc, increment m_pc.
 * 2. Add X to this value, use only lower 8 bits of the result
 * 3. Then read the byte at this calculated address
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_addr  Client address of the addressed byte
 *      m_data  Byte read from there
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_zpx
        @ read argument at PC (zeropage address)
        ldrb    m_addr, [m_pc], #1

        @ now m_addr contains the zp address, add it shifted to X
        @ into m_addr[31:24]
        x_to_tmp
        add     m_addr, m_tmp, m_addr, lsl #24

        @ correct the bit positions
        mov     m_addr, m_addr, lsr #24

        @ read m_data from there
        ldr     m_tmp, =c1541_ram
        ldrb    m_data, [m_tmp, m_addr]
.endm

/*******************************************************************************
 * Zeropage,X addressing mode (write)
 * 1. Read one byte at m_pc, increment m_pc.
 * 2. Add X to this value, use only lower 8 bits of the result
 * 3. Write the byte from m_data to the address calculated above
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *      m_data  Byte to be written
 *
 * Out: m_addr  Changed (!!!)
 *      m_tmp   Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_zpx
        @ read argument at PC (zeropage address)
        ldrb    m_addr, [m_pc], #1

        @ now m_addr contains the zp address, add it shifted to X into m_addr[31:24]
        x_to_tmp
        add     m_addr, m_tmp, m_addr, lsl #24

        @ write m_data to there. correct the bit positions
        ldr     m_tmp, =c1541_ram
        strb    m_data, [m_tmp, m_addr, lsr #24]
.endm


/*******************************************************************************
 * Zeropage,Y addressing mode (read)
 * 1. Read one byte at m_pc, increment m_pc.
 * 2. Add Y to this value, use only lower 8 bits of the result
 * 3. Then read the byte at this calculated address
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_addr  Client address of the addressed byte
 *      m_data  Byte read from there
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_zpy
        @ read argument at PC (zeropage address)
        ldrb    m_addr, [m_pc], #1

        @ now m_addr contains the zp address, add it shifted to Y
        @ into m_addr[31:24]
        y_to_tmp
        add     m_addr, m_tmp, m_addr, lsl #24

        @ correct the bit positions
        mov     m_addr, m_addr, lsr #24

        @ read m_data from there
        ldr     m_tmp, =c1541_ram
        ldrb    m_data, [m_tmp, m_addr]
.endm

/*******************************************************************************
 * Zeropage,Y addressing mode (write)
 * 1. Read one byte at m_pc, increment m_pc.
 * 2. Add Y to this value, use only lower 8 bits of the result
 * 3. Write the byte from m_data to the address calculated above
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *      m_data  Byte to be written
 *
 * Out: m_addr  Changed (!!!)
 *      m_tmp   Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_zpy
        @ read argument at PC (zeropage address)
        ldrb    m_addr, [m_pc], #1

        @ now m_addr contains the zp address, add it shifted to Y into m_addr[31:24]
        y_to_tmp
        add     m_addr, m_tmp, m_addr, lsl #24

        @ write m_data to there. correct the bit positions
        ldr     m_tmp, =c1541_ram
        strb    m_data, [m_tmp, m_addr, lsr #24]
.endm

/*******************************************************************************
 * Absolute addressing mode (read)
 * 1. Read two bytes argument at m_pc, increment m_pc two times
 * 2. Read the byte pointed to by the byte read in step 1
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_addr  Client address of the byte
 *      m_data  The byte
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_abs
        memr_pc_arg16

        @ now m_addr contains the address, read a byte from there
        memr_addr
.endm

/*******************************************************************************
 * Absolute addressing mode (write)
 * 1. Read two bytes argument at m_pc, increment m_pc two times
 * 2. Write m_data to the address read in step 1
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *      m_data  The byte to be written
 *
 * Out: m_addr  Changed (!!!)
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_abs
        memr_pc_arg16

        @ now m_addr contains the address, write the byte m_data to there
        memw_data_to_addr
.endm

/*******************************************************************************
 * Absolute,X addressing mode (read)
 * 1. Read two bytes argument at m_pc, increment m_pc two times
 * 2. Add X to this value, use only lower 16 bits of the result
 * 3. Then read the byte at this calculated address
 * One penalty cycle is added here if the page wraps.
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_addr  Client address of the byte
 *      m_data  The byte
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_absx
        memr_pc_arg16

        @ now m_addr[15:0] contains the address, remember the high-byte in m_data[7:0]
        mov m_tmp, m_addr, lsr #8

        @ add X to address and remove overflow bit
        x_to_data_low
        add m_addr, m_addr, m_data
        bic m_addr, m_addr, #(1 << 16)

        @ check if high-byte remained same
        teq m_tmp, m_addr, lsr #8

        @ if not, add one cycle
        addne m_t, m_t, #1

        @ now m_addr contains the address, read a byte from there
        memr_addr
.endm

/*******************************************************************************
 * Absolute,X addressing mode (read), w/o penalty cycle
 * 1. Read two bytes argument at m_pc, increment m_pc two times
 * 2. Add X to this value, use only lower 16 bits of the result
 * 3. Then read the byte at this calculated address
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_addr  Client address of the byte
 *      m_data  The byte
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_absx0
        memr_pc_arg16

        @ add X to address and remove overflow bit
        x_to_data_low
        add m_addr, m_addr, m_data
        bic m_addr, m_addr, #(1 << 16)

        @ now m_addr contains the address, read a byte from there
        memr_addr
.endm

/*******************************************************************************
 * Absolute,X addressing mode (write)
 * 1. Read two bytes argument at m_pc, increment m_pc two times
 * 2. Add X to this value, use only lower 16 bits of the result
 * 3. Write the byte from r1[7:0] to the address calculated above
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *      m_data  The byte to be written
 *
 * Out: m_addr  Changed (!!!)
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_absx
        memr_pc_arg16

        @ add X to address and remove overflow bit
        x_to_tmp
        add m_addr, m_addr, m_tmp, lsr #24
        bic m_addr, m_addr, #(1 << 16)

        @ now m_addr contains the address, write the byte m_data to there
        memw_data_to_addr
.endm

/*******************************************************************************
 * Absolute,Y addressing mode (read)
 * 1. Read two bytes argument at m_pc, increment m_pc two times
 * 2. Add Y to this value, use only lower 16 bits of the result
 * 3. Then read the byte at this calculated address
 * One penalty cycle is added here if the page wraps.
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_addr  Client address of the byte
 *      m_data  The byte
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_absy
        memr_pc_arg16

        @ now m_addr[15:0] contains the address, remember the high-byte in m_data[7:0]
        mov m_tmp, m_addr, lsr #8

        @ add Y to address and remove overflow bit
        y_to_data_low
        add m_addr, m_addr, m_data
        bic m_addr, m_addr, #(1 << 16)

        @ check if high-byte remained same
        teq m_tmp, m_addr, lsr #8

        @ if not, add one cycle
        addne m_t, m_t, #1

        @ now m_addr contains the address, read a byte from there
        memr_addr
.endm

/*******************************************************************************
 * Absolute,Y addressing mode (write)
 * 1. Read two bytes argument at m_pc, increment m_pc two times
 * 2. Add Y to this value, use only lower 16 bits of the result
 * 3. Write the byte from r1[7:0] to the address calculated above
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *      m_data  The byte to be written
 *
 * Out: m_addr  Changed (!!!)
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_absy
        memr_pc_arg16

        @ add Y to address and remove overflow bit
        y_to_tmp
        add m_addr, m_addr, m_tmp, lsr #24
        bic m_addr, m_addr, #(1 << 16)

        @ now m_addr contains the address, write the byte m_data to there
        memw_data_to_addr
.endm

/*******************************************************************************
 * (Indirect,X) adressing mode (read)
 * 1. Read one byte argument at m_pc, increment m_pc
 * 2. Add X to this value, use only lower 8 bits of the result
 * 3. Then read two bytes at this calculated address, that's the address we need
 * 4. Load the value from there
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_addr  Client address of the addressed byte
 *      m_data  Byte read from there
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_indx
        @ read argument at PC (zeropage address)
        ldrb    m_tmp, [m_pc], #1

        @ add it to X into m_tmp[31:24]
        x_to_data
        add     m_tmp, m_data, m_tmp, lsl #24

        @ load a byte from there, that's the low byte of the address
        ldr     m_addr, =c1541_ram
        ldrb    m_data, [m_addr, m_tmp, lsr #24]

        @ the next one is the high byte, merge them into m_addr
        add     m_tmp, m_tmp, #(1 << 24)
        ldrb    m_tmp, [m_addr, m_tmp, lsr #24]
        orr     m_addr, m_data, m_tmp, lsl #8

        @ now m_addr contains the address, read a byte from there
        memr_addr
.endm

/*******************************************************************************
 * (Indirect,X) adressing mode (write)
 * 1. Read one byte argument at m_pc, increment m_pc
 * 2. Add X to this value, use only lower 8 bits of the result
 * 3. Then read two bytes at this calculated address, that's the address we need
 * 4. Store m_data to there
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *      m_data  Byte to be written
 *
 * Out: m_addr  Changed (!!!)
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_indx
        @ read argument at PC (zeropage address)
        ldrb    lr, [m_pc], #1

        @ add it to X into m_tmp[31:24]
        x_to_tmp
        add     m_tmp, m_tmp, lr, lsl #24

        @ load a byte from there, that's the low byte of the address
        ldr     lr, =c1541_ram
        ldrb    m_addr, [lr, m_tmp, lsr #24]

        @ the next one is the high byte, merge them into m_addr
        add     m_tmp, m_tmp, #(1 << 24)
        ldrb    m_tmp, [lr, m_tmp, lsr #24]
        orr     m_addr, m_addr, m_tmp, lsl #8

        @ now m_addr contains the address, write the byte m_data to there
        memw_data_to_addr
.endm

/*******************************************************************************
 * (Indirect),Y adressing mode (read)
 * 1. Read one byte argument at m_pc, increment m_pc
 * 2. Read two bytes at this, that's the base address
 * 3. Add Y to this base address, use only lower 16 bits of the result
 * 4. Load the value from there
 * One penalty cycle is added here if the page wraps.
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *
 * Out: m_addr  Client address of the addressed byte
 *      m_data  Byte read from there
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_indy
        @ read argument at PC (zeropage address)
        ldrb    m_addr, [m_pc], #1

        @ now m_addr contains the zp address
        @ load a byte from there, that's the low byte of the address
        ldr     m_tmp, =c1541_ram
        ldrb    m_data, [m_tmp, m_addr]

        @ the next one is the high byte, merge them into m_addr
        add     m_addr, m_addr, #1
        and     m_addr, m_addr, #0xff
        ldrb    m_tmp, [m_tmp, m_addr]
        orr     m_addr, m_data, m_tmp, lsl #8

        @ remember high-byte of address
        mov     m_data, m_addr, lsr #8

        @ add Y to it, use 16 bits only
        y_to_tmp
        add     m_addr, m_addr, m_tmp, lsr #24
        bic     m_addr, m_addr, #(1 << 16)

        @ check if high-byte remained same
        cmp     m_data, m_addr, lsr #8

        @ if not, add one cycle
        addne m_t, m_t, #1

        @ now m_addr contains the address, read a byte from there
        memr_addr
.endm

/*******************************************************************************
 * (Indirect),Y adressing mode (write)
 * 1. Read one byte argument at m_pc, increment m_pc
 * 2. Read two bytes at this, that's the base address
 * 3. Add Y to this base address, use only lower 16 bits of the result
 * 4. Store m_data to there
 *
 * In:  m_pc    Points to native memory corresponding to PC
 *      m_data  Byte to be written
 *
 * Out: m_addr  Changed (!!!)
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_indy
        @ read argument behind PC (zeropage address)
        ldrb    m_tmp, [m_pc], #1

        @ load a byte from there, that's the low byte of the address
        ldr     lr, =c1541_ram
        ldrb    m_addr, [lr, m_tmp]

        @ the next one is the high byte, merge them into m_addr
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff
        ldrb    m_tmp, [lr, m_tmp]
        orr     m_addr, m_addr, m_tmp, lsl #8

        @ add Y to it, use 16 bits only
        y_to_tmp
        add     m_addr, m_addr, m_tmp, lsr #24
        bic     m_addr, m_addr, #(1 << 16)

        @ now m_addr contains the address, write the byte m_data to there
        memw_data_to_addr
.endm

/*******************************************************************************
 * Write a byte to zero page
 *
 * 1. Read one byte argument behind m_pc.
 * 2. Write the byte from m_dataq[7:0] to the address read at step 1
 *
 * In:  m_addr  Client address of the addressed byte, must be < 0x100
 *      m_data  Byte to be written
 *
 * Out: m_tmp   Changed
 *
 ******************************************************************************/
.macro  memw_zp
        @ store data byte to that address into RAM
        ldr     m_tmp, =c1541_ram
        strb    m_data, [m_tmp, m_addr]
.endm

/*******************************************************************************
 * Increment the PC by the given number, set the CPU emulation timer to expire
 * in 'time' microseconds and return from FIQ
 ******************************************************************************/
.macro op_end time
        @ Set next timer
        add     m_t, m_t, #\time
        b       mos6502_op_end
.endm

/*******************************************************************************
 * Update 6502 flags N and Z with flags from ARM
 *
 * Out: m_flags    Flags updated
 ******************************************************************************/
.macro update_nz
        bic       m_flags, m_flags, #(MOS6502_N | MOS6502_Z)
        orrmi     m_flags, m_flags, #MOS6502_N
        orreq     m_flags, m_flags, #MOS6502_Z
.endm

/*******************************************************************************
 * Update 6502 flags NZC with flags from ARM
 *
 * Out: m_flags    Flags updated
 *      m_tmp   Changed
 ******************************************************************************/
.macro update_nzc
        mrs     m_tmp, cpsr         @ get PSR into m_tmp

        @ isolate flags from CPSR and put them into 6502 flags
        and     m_tmp, m_tmp, #(MOS6502_N | MOS6502_Z | MOS6502_C)
        bic     m_flags, m_flags, #(MOS6502_N | MOS6502_Z | MOS6502_C)
        orr     m_flags, m_flags, m_tmp   @ copy flags to 6502
.endm

/*******************************************************************************
 * Update 6502 flags NZCV with flags from ARM
 *
 * Out: m_flags    Flags updated
 *      m_tmp   Changed
 ******************************************************************************/
.macro update_nzcv
        mrs m_tmp, cpsr             @ get PSR into m_tmp

        @ isolate flags from CPSR and put them into 6502 flags
        and     m_tmp, m_tmp, #(MOS6502_N | MOS6502_Z | MOS6502_C | MOS6502_V)
        bic     m_flags, m_flags, #(MOS6502_N | MOS6502_Z | MOS6502_C | MOS6502_V)
        orr     m_flags, m_flags, m_tmp   @ copy flags to 6502
.endm

#endif // MOS6502_MACROS_H
