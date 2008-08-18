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
@ NZCVDI00 000000Sx PPPPPPPP PPPPPPPP
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
MOS6502_D   = (1 << 27)
MOS6502_I   = (1 << 26)

MOS6502_S   = (1 << 17)

@ This mask leaves only bits used by the emulation
MOS6502_PC_EMU_MASK = 0x00ff0000

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

        @ each table entry points to 0x0800 bytes, use the higher bits
        and m_tmp, m_addr, #0xf800

        @ prepare link register, will return 2 instructions behind this
        mov lr, pc

        @ call the right handler
        ldr pc, [m_data, m_tmp, lsr #(11 - 2)]
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

        @ each table entry points to 0x0800 bytes, use the higher bits
        add m_tmp, m_tmp, m_addr, lsr #(11 - 2)
        bic m_tmp, m_tmp, #3

        @ prepare link register, will return 2 instructions behind this
        mov lr, pc

        @ jump to the right handler
        ldr pc, [m_tmp]
.endm

/*******************************************************************************
 * Read one byte argument behind m_pc.
 * This macros uses m_addr which must point to the opcode in the native memory.
 * It reads *(pc + 1)
 *
 * In:  m_addr  Points to native memory related to m_pc
 *
 * Out: m_data  The byte
 *
 ******************************************************************************/
.macro  memr_pc_arg8
        ldrb    m_data, [m_addr, #1]
.endm

/*******************************************************************************
 * Read a two byte argument behind m_pc.
 * This macros uses m_addr which must point to the opcode in the native memory.
 * It reads *(pc + 1) | (*(pc + 2) << 8).
 *
 * In:  m_addr  Points to native memory related to m_pc
 *
 * Out: m_addr  Two bytes behind opcode (little endian [15:0] )
 *      m_tmp   Changed
 *
 *
 ******************************************************************************/
.macro  memr_pc_arg16
        ldrb    m_tmp, [m_addr, #1]
        ldrb    m_addr, [m_addr, #2]
        orr     m_addr, m_tmp, m_addr, lsl #8
.endm

/*******************************************************************************
 * Zero page addressing mode (read)
 * 1. Read one byte argument behind m_pc.
 * 2. Then read the byte pointed to by the byte read at step 1
 *
 * In:  m_addr  Points to the opcode in the native memory
 *
 * Out: m_addr  Client address of the byte
 *      m_data  The byte
 *      m_tmp   Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_zp
        @ read argument behind PC (zeropage address)
        ldrb    m_addr, [m_addr, #1]

        @ now m_addr contains the zp address, read a byte from there
        ldr     m_tmp, =c1541_ram
        ldrb    m_data, [m_tmp, m_addr]
.endm

/*******************************************************************************
 * Zero page addressing mode (write)
 * 1. Read one byte argument behind m_pc.
 * 2. Write the byte from m_dataq[7:0] to the address read at step 1
 *
 * In:  m_addr  Points to the opcode in the native memory
 *      m_data  Byte to be written
 *
 * Out: m_addr  Client address of the byte
 *      m_tmp   Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_zp
        @ read argument behind PC (zeropage address)
        ldrb    m_addr, [m_addr, #1]

        @ store data byte to that address into RAM
        ldr     m_tmp, =c1541_ram
        strb    m_data, [m_tmp, m_addr]
.endm

/*******************************************************************************
 * Zeropage,X addressing mode (read)
 * 1. Read one byte argument behind m_pc
 * 2. Add X to this value, use only lower 8 bits of the result
 * 3. Then read the byte at this calculated address
 *
 * In:  m_addr  Points to the opcode in the native memory
 *
 * Out: m_addr  Client address of the addressed byte
 *      m_data  Byte read from there
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_zpx
        @ read argument behind PC (zeropage address)
        ldrb    m_addr, [m_addr, #1]

        @ now m_addr contains the zp address, add it shifted to X into r0[31:24]
        add     m_addr, m_x, m_addr, lsl #24

        @ correct the bit positions
        mov     m_addr, m_addr, lsr #24

        @ read m_data from there
        ldr     m_tmp, =c1541_ram
        ldrb    m_data, [m_tmp, m_addr]
.endm

/*******************************************************************************
 * Zeropage,X addressing mode (write)
 * 1. Read one byte argument behind m_pc
 * 2. Add X to this value, use only lower 8 bits of the result
 * 3. Write the byte from m_data to the address calculated above
 *
 * In:  m_addr  Points to the opcode in the native memory
 *      m_data  Byte to be written
 *
 * Out: m_addr  Changed (!!!)
 *      m_tmp   Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_zpx
        @ read argument behind PC (zeropage address)
        ldrb    m_addr, [m_addr, #1]

        @ now m_addr contains the zp address, add it shifted to X into m_addr[31:24]
        add     m_addr, m_x, m_addr, lsl #24

        @ write m_data to there. correct the bit positions
        ldr     m_tmp, =c1541_ram
        strb    m_data, [m_tmp, m_addr, lsr #24]
.endm


/*******************************************************************************
 * Zeropage,Y addressing mode (read)
 * 1. Read one byte argument behind m_pc
 * 2. Add Y to this value, use only lower 8 bits of the result
 * 3. Then read the byte at this calculated address
 *
 * In:  m_addr  Points to the opcode in the native memory
 *
 * Out: m_addr  Client address of the addressed byte
 *      m_data  Byte read from there
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_zpy
        @ read argument behind PC (zeropage address)
        ldrb    m_addr, [m_addr, #1]

        @ now m_addr contains the zp address, add it shifted to Y into r0[31:24]
        add     m_addr, m_y, m_addr, lsl #24

        @ correct the bit positions
        mov     m_addr, m_addr, lsr #24

        @ read m_data from there
        ldr     m_tmp, =c1541_ram
        ldrb    m_data, [m_tmp, m_addr]
.endm

/*******************************************************************************
 * Absolute addressing mode (read)
 * 1. Read two bytes argument behind m_pc
 * 2. Read the byte pointed to by the byte read in step 1
 *
 * In:  m_addr  Points to the opcode in the native memory
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
 * 1. Read two bytes argument behind m_pc.
 * 2. Write m_data to the address read in step 1
 *
 * In:  m_addr  Points to the opcode in the native memory
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
 * 1. Read two bytes argument behind m_pc.
 * 2. Add X to this value, use only lower 16 bits of the result
 * 3. Then read the byte at this calculated address
 * One penalty cycle is added here if the page wraps.
 *
 * In:  m_addr  Points to the opcode in the native memory
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
        add m_addr, m_addr, m_x, lsr #24
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
 * 1. Read two bytes argument behind m_pc.
 * 2. Add X to this value, use only lower 16 bits of the result
 * 3. Then read the byte at this calculated address
 *
 * In:  m_addr  Points to the opcode in the native memory
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
        add m_addr, m_addr, m_x, lsr #24
        bic m_addr, m_addr, #(1 << 16)

        @ now m_addr contains the address, read a byte from there
        memr_addr
.endm

/*******************************************************************************
 * Absolute,X addressing mode (write)
 * 1. Read two bytes argument behind m_pc.
 * 2. Add X to this value, use only lower 16 bits of the result
 * 3. Write the byte from r1[7:0] to the address calculated above
 *
 * In:  m_addr  Points to the opcode in the native memory
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
        add m_addr, m_addr, m_x, lsr #24
        bic m_addr, m_addr, #(1 << 16)

        @ now m_addr contains the address, write the byte m_data to there
        memw_data_to_addr
.endm

/*******************************************************************************
 * Absolute,Y addressing mode (read)
 * 1. Read two bytes argument behind m_pc.
 * 2. Add Y to this value, use only lower 16 bits of the result
 * 3. Then read the byte at this calculated address
 * One penalty cycle is added here if the page wraps.
 *
 * In:  m_addr  Points to the opcode in the native memory
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
        add m_addr, m_addr, m_y, lsr #24
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
 * 1. Read two bytes argument behind m_pc.
 * 2. Add Y to this value, use only lower 16 bits of the result
 * 3. Write the byte from r1[7:0] to the address calculated above
 *
 * In:  m_addr  Points to the opcode in the native memory
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
        add m_addr, m_addr, m_y, lsr #24
        bic m_addr, m_addr, #(1 << 16)

        @ now m_addr contains the address, write the byte m_data to there
        memw_data_to_addr
.endm

/*******************************************************************************
 * (Indirect,X) adressing mode (read)
 * 1. Read one byte argument behind m_pc.
 * 2. Add X to this value, use only lower 8 bits of the result
 * 3. Then read two bytes at this calculated address, that's the address we need
 * 4. Load the value from there
 *
 * In:  m_addr  Points to the opcode in the native memory
 *
 * Out: m_addr  Client address of the addressed byte
 *      m_data  Byte read from there
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_indx
        @ read argument behind PC (zeropage address)
        ldrb    m_tmp, [m_addr, #1]

        @ add it to X into m_tmp[31:24]
        add     m_tmp, m_x, m_tmp, lsl #24

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
 * 1. Read one byte argument behind m_pc.
 * 2. Add X to this value, use only lower 8 bits of the result
 * 3. Then read two bytes at this calculated address, that's the address we need
 * 4. Store m_data to there
 *
 * In:  m_addr  Points to the opcode in the native memory
 *      m_data  Byte to be written
 *
 * Out: m_addr  Changed (!!!)
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_indx
        @ read argument behind PC (zeropage address)
        ldrb    m_tmp, [m_addr, #1]

        @ add it to X into m_tmp[31:24]
        add     m_tmp, m_x, m_tmp, lsl #24

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
 * 1. Read one byte argument behind m_pc
 * 2. Read two bytes at this, that's the base address
 * 3. Add Y to this base address, use only lower 16 bits of the result
 * 4. Load the value from there
 * One penalty cycle is added here if the page wraps.
 *
 * In:  m_addr  Points to the opcode in the native memory
 *
 * Out: m_addr  Client address of the addressed byte
 *      m_data  Byte read from there
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memr_addr_mode_indy
        @ read argument behind PC (zeropage address)
        ldrb    m_addr, [m_addr, #1]

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
        mov     m_data, m_addr, lsr #24

        @ add Y to it, use 16 bits only
        add     m_addr, m_addr, m_y, lsr #24
        bic     m_addr, m_addr, #(1 << 16)

        @ check if high-byte remained same
        teq     m_data, m_addr, lsr #8

        @ if not, add one cycle
        addne m_t, m_t, #1

        @ now m_addr contains the address, read a byte from there
        memr_addr
.endm

/*******************************************************************************
 * (Indirect),Y adressing mode (write)
 * 1. Read one byte argument behind m_pc
 * 2. Read two bytes at this, that's the base address
 * 3. Add Y to this base address, use only lower 16 bits of the result
 * 4. Store m_data to there
 *
 * In:  m_addr  Points to the opcode in the native memory
 *      m_data  Byte to be written
 *
 * Out: m_addr  Changed (!!!)
 *      m_tmp   Changed
 *      lr      Changed
 *
 ******************************************************************************/
.macro  memw_addr_mode_indy
        @ read argument behind PC (zeropage address)
        ldrb    m_tmp, [m_addr, #1]

        @ load a byte from there, that's the low byte of the address
        ldr     lr, =c1541_ram
        ldrb    m_addr, [lr, m_tmp]

        @ the next one is the high byte, merge them into m_addr
        add     m_tmp, m_tmp, #1
        and     m_tmp, m_tmp, #0xff
        ldrb    m_tmp, [lr, m_tmp]
        orr     m_addr, m_addr, m_tmp, lsl #8

        @ add Y to it, use 16 bits only
        add     m_addr, m_addr, m_y, lsr #24
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
 * Increment PC by the given value.
 *
 * In:  m_pc    Current client PC
 *      num     Number of bytes to add
 *
 * Out: m_pc    Increased by num
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
 * If the emulated CPU is in single step mode, the new time is calculated but
 * not programmed to the hardware timer. The timer IRQ is Ack'd in any case.
 *
 * In:  m_t     Current client CPU time
 *      time    Number of microseconds for current operation
 *
 * Out: m_t     Increased by 'time'
 *      m_addr  Changed
 *      m_tmp   changed
 *
 ******************************************************************************/
.macro inc_time time
        @ Ack timer 0 interrupt
        mov     m_tmp, #TIR_MR0
        mov     m_addr, #(T0IR & 0xffff0000)
        orr     m_addr, m_addr, #(T0IR & 0x0000ffff)
        str     m_tmp, [m_addr]

        @ Set next timer
        add     m_t, m_t, #\time

        @ Change address from T0IR to T0MR
        add     m_addr, m_addr, #(T0MR0 - T0IR)

        @ program the timer match register if not in single step mode
        tst     m_pc, #MOS6502_S
        streq   m_t, [m_addr]
.endm

/*******************************************************************************
 * Increment the PC by the given number, set the CPU emulation timer to expire
 * in 'time' microseconds and return from FIQ
 ******************************************************************************/
.macro op_end pc time
        inc_pc \pc
        inc_time \time
        ret_fiq
.endm

/*******************************************************************************
 * Update 6502 flags N and Z with flags from ARM
 *
 * Out: m_pc    Flags updated
 ******************************************************************************/
.macro update_nz
        bic       m_pc, m_pc, #(MOS6502_N | MOS6502_Z)
        orrmi     m_pc, m_pc, #MOS6502_N
        orreq     m_pc, m_pc, #MOS6502_Z
.endm

/*******************************************************************************
 * Update 6502 flags NZC with flags from ARM
 *
 * Out: m_pc    Flags updated
 *      m_tmp   Changed
 ******************************************************************************/
.macro update_nzc
        mrs     m_tmp, cpsr         @ get PSR into m_tmp

        @ isolate flags from CPSR and put them into 6502 flags
        and     m_tmp, m_tmp, #(MOS6502_N | MOS6502_Z | MOS6502_C)
        bic     m_pc, m_pc, #(MOS6502_N | MOS6502_Z | MOS6502_C)
        orr     m_pc, m_pc, m_tmp   @ copy flags to 6502
.endm

/*******************************************************************************
 * Update 6502 flags NZCV with flags from ARM
 *
 * Out: m_pc    Flags updated
 *      m_tmp   Changed
 ******************************************************************************/
.macro update_nzcv
        mrs m_tmp, cpsr             @ get PSR into r0

        @ isolate flags from CPSR and put them into 6502 flags
        and     m_tmp, m_tmp, #(MOS6502_N | MOS6502_Z | MOS6502_C | MOS6502_V)
        bic     m_pc, m_pc, #(MOS6502_N | MOS6502_Z | MOS6502_C | MOS6502_V)
        orr     m_pc, m_pc, m_tmp   @ copy flags to 6502
.endm

