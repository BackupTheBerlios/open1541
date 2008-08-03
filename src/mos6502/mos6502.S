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

/*
 * Known limitations:
 * - Multibyte instructions at the end of memory are not executed correctly,
 *   the PC doesn't wrap around to $0000 in the middle of an instruction.
 * - Decimal mode not implemented yet
 */

#include <arm7tdmi.h>
#include <lpc213x.h>

#include "mos6502_macros.S"


        .code 32
        .text

/*******************************************************************************
 *
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_reg_init
mos6502_reg_init:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ set time to start exec in 1 ms
        ldr     r1, =T0TC
        ldr     m_t, [r1]
        add     m_t, m_t, #1024
        ldr     r1, =T0MR0
        str     m_t, [r1]

        @ set all regs to 0
        mov     m_a, #0
        mov     m_x, #0
        mov     m_y, #0

        @ todo: Read start address from reset vector
        mov     m_pc, #0

        b       exit_fiq_mode

/*******************************************************************************
 * Copy the processor regs into mos6502_regs_t pointed to by r0.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_store_regs
mos6502_store_regs:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        stmia   r0!, {r8}   @ time
        mov     r1, r9, lsr#24  @ a
        stmia   r0!, {r1}
        mov     r1, r10, lsr#24 @ x
        stmia   r0!, {r1}
        mov     r1, r11, lsr#24 @ y
        stmia   r0!, {r1}
        stmia   r0!, {r12}  @ pc, flags

        b       exit_fiq_mode

/*******************************************************************************
 * Return the emulated PC in R0. To be called from system mode.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_get_pc
mos6502_get_pc:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ copy PC to R0, shift away unused bits
        mov     r0, m_pc, lsl #16
        mov     r0, r0, lsr #16

        b       exit_fiq_mode

/*******************************************************************************
 * Read from emulated memory pointed to by r0, return the result in r0.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_read_mem
mos6502_read_mem:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ read memory and return
        mr_r0
        b       exit_fiq_mode

/*******************************************************************************
 * Put the 6502 into single step mode.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_stop
mos6502_stop:
        @ remember old processor and interrupt state
        mrs r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ Set single step mode
        orr m_pc, m_pc, #MOS6502_S

exit_fiq_mode:
        @ restore old processor and interrupt state, return
        msr cpsr_c, r3
        mov pc, r14

/*******************************************************************************
 * Execute one instruction. If the emulation is not in single step mode
 * this function does nothing.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_step
mos6502_step:
        @ remember old processor and interrupt state
        mrs     r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr     cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ Check for single step mode
        tst     m_pc, #MOS6502_S
        beq     exit_fiq_mode

        @ program the timer match register 0 to expire in 2 us
        ldr     r1, =T0TC
        ldr     r0, [r1]
        add     r0, r0, #2
        add     r1, r1, #(T0MR0 - T0TC) @ point to T0MCR0 now
        str     r0, [r1]

        @ restore old processor and interrupt state
        msr     cpsr_c, r3

        @ wait until IRQ time is over
        sub     r1, r1, #(T0MR0 - T0TC) @ point to T0TC again
step_wait:
        ldr     r2, [r1]
        subs    r3, r0, r2
        bpl     step_wait

        mov     pc, lr

/*******************************************************************************
 * Continue from single step mode. If the emulation is not in single step mode
 * this function does nothing.
 * Must be called from system mode (not from FIQ mode).
 *
 ******************************************************************************/
        .global mos6502_continue
mos6502_continue:
        @ remember old processor and interrupt state
        mrs r3, cpsr

        @ disable IRQs so we won't be disturbed, goto FIQ mode
        msr cpsr_c, #MODE_FIQ | PSR_I | PSR_F

        @ Check for single step mode
        tst m_pc, #MOS6502_S
        beq 1f

        @ Delete bit for single step mode
        bic m_pc, #MOS6502_S

        @ program the timer match register 0 to expire in 2 us
        ldr r1, =T0TC
        ldr m_t, [r1]
        add m_t, m_t, #2
        add r1, r1, #(T0MR0 - T0TC)
        str m_t, [r1]
1:
        b exit_fiq_mode

/*******************************************************************************
 * Here there are all basic operations (ALU etc.) implemented.
 * These macros are used in the real opcode implementations below.
 *
 ******************************************************************************/

@ Increment PC by the given value.
.macro inc_pc num
.ifne \num
        add m_pc, m_pc, #\num
        @ todo: Delete bit 16 at a convinient place. This may be set if the PC
        @ wraps from 0xffff to 0, Don't wanna spend a cycle here for this
        @ unlikely case
.endif
.endm

@ Set the CPU emulation timer to expire in 'time' microseconds.
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

@ Increment the PC by the given number,
@ Set the CPU emulation timer to expire in 'time' microseconds,
@ Return from FIQ
.macro op_end pc time
        inc_pc \pc
        inc_time \time
        ret_fiq
.endm

@ Update 6502 flags N and Z with flags from ARM
.macro update_nz
        bic       m_pc, m_pc, #(MOS6502_N | MOS6502_Z)
        orrmi     m_pc, m_pc, #MOS6502_N
        orreq     m_pc, m_pc, #MOS6502_Z
.endm

@ Update 6502 flags NZCV with flags from ARM
.macro update_nzcv
        mrs r0, cpsr                @ get PSR into r0
        and r0, r0, #0xff000000     @ isolate flags
        bic m_pc, m_pc, #0xff000000 @ clear 6502 flags
        orr m_pc, m_pc, r0          @ copy flags to 6502
.endm

@ Do an ADC, the argument is in r0[0-7]
.macro do_adc
        movs r1, m_pc, lsl #3       @ set ARM C from 6502 C
                                    @ prepare summand if CS:
        mvncs r1, #0xff000000       @   set bits 0-23 so ARM C gets helpful
        orrcs r1, r1, r0, lsl #24   @   put summand into 24-31
                                    @ else prepare summand if CC:
        movcc r1, r0, lsl #24       @   put summand into 24-31
        adcs  m_a, m_a, r1          @ perform ADC and set ARM flags
        update_nzcv
.endm

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

/*******************************************************************************
 * Here there are all opcodes implemented.
 *
 * On entry:
 * Registers r8..r12 (m_t, m_a, m_x, m_y, m_pc) contain the current emulation
 * state as described in mos6502_macros.S.
 *
 * m_t contains the time when the instruction starts to be executed.
 *
 * r2  points to the native memory corresponding to the emulated PC. so it
 *     points to the byte behind the current opcode. This will be used by the
 *     macros mr_pc_arg8 or mr_pc_arg16
 *
 * r0 to r2 can be used as scratch registers and don't need to be restored
 *
 ******************************************************************************/

        .global op_10
op_10:  @ BPL
        tst m_pc, #MOS6502_N    @ check if emulated N bit is set
        bne no_branch           @ set => no branch
        do_branch

        .global op_18
op_18:  @ CLC
        bic m_pc, #MOS6502_C
        op_end 1 2

        .global op_30
op_30:  @ BMI
        tst m_pc, #MOS6502_N    @ check if emulated N bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_38
op_38:  @ SEC
        orr m_pc, m_pc, #MOS6502_C
        op_end 1 2

        .global op_4c
op_4c:  @ JMP abs
        mr_pc_arg16
        mov m_pc, m_pc, lsr #16     @ remove old PC
        add m_pc, r0, m_pc, lsl #16 @ set new PC
        op_end 0 3

        .global op_50
op_50:  @ BVC
        tst m_pc, #MOS6502_V    @ check if emulated V bit is set
        bne no_branch           @ set => no branch
        do_branch

        .global op_58
op_58:  @ CLI
        bic m_pc, #MOS6502_I
        op_end 1 2

        .global op_65
op_65: @ ADC $FF
        mr_addr_mode_zp
        do_adc
        op_end 2 3

        .global op_69
op_69:  @ ADC #$xx
        mr_pc_arg8
        do_adc
        op_end 2 2

        .global op_6d
op_6d: @ ADC $FFFF
        mr_addr_mode_abs
        do_adc
        op_end 3 4

        .global op_70
op_70:  @ BVS
        tst m_pc, #MOS6502_V    @ check if emulated V bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_75
op_75: @ ADC $FF,X
        mr_addr_mode_zpx
        do_adc
        op_end 2 4

        .global op_78
op_78:  @ SEI
        orr m_pc, m_pc, #MOS6502_I
        op_end 1 2

        .global op_79
op_79: @ ADC $FFFF,Y
        mr_addr_mode_absy       @ this increments m_t on page wraps
        do_adc
        op_end 3 4

        .global op_7d
op_7d: @ ADC $FFFF,X
        mr_addr_mode_absx       @ this increments m_t on page wraps
        do_adc
        op_end 3 4

        .global op_88
op_88: @ DEY
        subs m_y, m_y, #(1<<24) @ dec Y, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_8a
op_8a: @ TXA
        movs m_a, m_x
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_90
op_90:  @ BCC
        tst m_pc, #MOS6502_C    @ check if emulated C bit is set
        bne no_branch           @ set => no branch
        do_branch

        .global op_98
op_98: @ TYA
        movs m_a, m_y
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_a0
op_a0:  @ LDY #xx
        mr_pc_arg8
        movs m_y, r0, lsl #24   @ load immediate, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 2 2

        .global op_a2
op_a2:  @ LDX #xx
        mr_pc_arg8
        movs m_x, r0, lsl #24   @ load immediate, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 2 2

        .global op_a4
op_a4:  @ LDY $xx
        mr_addr_mode_zp
        movs m_y, r0, lsl #24   @ move to reg, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 2 3

        .global op_a5
op_a5:  @ LDA $xx
        mr_addr_mode_zp
        movs m_a, r0, lsl #24   @ move to reg, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 2 3

        .global op_a6
op_a6:  @ LDX $xx
        mr_addr_mode_zp
        movs m_x, r0, lsl #24   @ move to reg, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 2 3

        .global op_a8
op_a8: @ TAY
        movs m_y, m_a
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_a9
op_a9:  @ LDA #xx
        mr_pc_arg8
        movs m_a, r0, lsl #24   @ load immediate, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 2 2

        .global op_aa
op_aa: @ TAX
        movs m_x, m_a
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_ad
op_ad: @ LDA $FFFF
        mr_addr_mode_abs
        movs m_a, r0, lsl #24   @ move to reg, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_b0
op_b0:  @ BCS
        tst m_pc, #MOS6502_C    @ check if emulated C bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_b5
op_b5: @ LDA $FF,X
        mr_addr_mode_zpx
        movs m_a, r0, lsl #24   @ move to reg, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 2 4

        .global op_b8
op_b8:  @ CLV
        bic m_pc, #MOS6502_V
        op_end 1 2

        .global op_b9
op_b9: @ LDA $FFFF,Y
        mr_addr_mode_absy       @ this increments m_t on page wraps
        movs m_a, r0, lsl #24   @ move to reg, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_bd
op_bd: @ LDA $FFFF,X
        mr_addr_mode_absx       @ this increments m_t on page wraps
        movs m_a, r0, lsl #24   @ move to reg, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 3 4

        .global op_c8
op_c8:  @ INY
        adds m_y, m_y, #(1<<24) @ inc Y, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_ca
op_ca: @ DEX
        subs m_x, m_x, #(1<<24) @ dec X, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_d0
op_d0:  @ BNE
        tst m_pc, #MOS6502_Z    @ check if emulated Z bit is set
        bne no_branch           @ set => no branch
        do_branch

no_branch:
        op_end 2 2

        .global op_d8
op_d8:  @ CLD
        bic m_pc, #MOS6502_D
        op_end 1 2

        .global op_e8
op_e8:  @ INX
        adds m_x, m_x, #(1<<24) @ inc X, update ARM flags
        update_nz               @ update 6502 flags N and Z
        op_end 1 2

        .global op_ea
op_ea:  @ NOP
        op_end 1 2

        .global op_f0
op_f0:  @ BEQ
        tst m_pc, #MOS6502_Z    @ check if emulated Z bit is set
        beq no_branch           @ clear => no branch
        do_branch

        .global op_f8
op_f8:  @ SED
        orr m_pc, m_pc, #MOS6502_D
        op_end 1 2

        .global op_xx


op_61: @ ADC ($FF,X)
op_71: @ ADC ($FF),Y
op_29: @ AND #$FF
op_25: @ AND $FF
op_35: @ AND $FF,X
op_2d: @ AND $FFFF
op_3d: @ AND $FFFF,X
op_39: @ AND $FFFF,Y
op_21: @ AND ($FF,X)
op_31: @ AND ($FF),Y
op_0a: @ ASL A
op_06: @ ASL $FF
op_16: @ ASL $FF,X
op_0e: @ ASL $FFFF
op_1e: @ ASL $FFFF,X
op_24: @ BIT $FF
op_2c: @ BIT $FFFF
op_00: @ BRK
op_c9: @ CMP #$FF
op_c5: @ CMP $FF
op_d5: @ CMP $FF,X
op_cd: @ CMP $FFFF
op_dd: @ CMP $FFFF,X
op_d9: @ CMP $FFFF,Y
op_c1: @ CMP ($FF,X)
op_d1: @ CMP ($FF),Y
op_e0: @ CPX #$FF
op_e4: @ CPX $FF
op_ec: @ CPX $FFFF
op_c0: @ CPY #$FF
op_c4: @ CPY $FF
op_cc: @ CPY $FFFF
op_c6: @ DEC $FF
op_d6: @ DEC $FF,X
op_ce: @ DEC $FFFF
op_de: @ DEC $FFFF,X
op_49: @ EOR #$FF
op_45: @ EOR $FF
op_55: @ EOR $FF,X
op_4d: @ EOR $FFFF
op_5d: @ EOR $FFFF,X
op_59: @ EOR $FFFF,Y
op_41: @ EOR ($FF,X)
op_51: @ EOR ($FF),Y
op_e6: @ INC $FF
op_f6: @ INC $FF,X
op_ee: @ INC $FFFF
op_fe: @ INC $FFFF,X
op_6c: @ JMP ($FFFF)
op_20: @ JSR $FFFF
op_a1: @ LDA ($FF,X)
op_b1: @ LDA ($FF),Y
op_b6: @ LDX $FF,Y
op_ae: @ LDX $FFFF
op_be: @ LDX $FFFF,Y
op_b4: @ LDY $FF,X
op_ac: @ LDY $FFFF
op_bc: @ LDY $FFFF,X
op_4a: @ LSR A
op_46: @ LSR $FF
op_56: @ LSR $FF,X
op_4e: @ LSR $FFFF
op_5e: @ LSR $FFFF,X
op_09: @ ORA #$FF
op_05: @ ORA $FF
op_15: @ ORA $FF,X
op_0d: @ ORA $FFFF
op_1d: @ ORA $FFFF,X
op_19: @ ORA $FFFF,Y
op_01: @ ORA ($FF,X)
op_11: @ ORA ($FF),Y
op_48: @ PHA
op_08: @ PHP
op_68: @ PLA
op_28: @ PLP
op_2a: @ ROL A
op_26: @ ROL $FF
op_36: @ ROL $FF,X
op_2e: @ ROL $FFFF
op_3e: @ ROL $FFFF,X
op_6a: @ ROR A
op_66: @ ROR $FF
op_76: @ ROR $FF,X
op_6e: @ ROR $FFFF
op_7e: @ ROR $FFFF,X
op_40: @ RTI
op_60: @ RTS
op_e9: @ SBC #$FF
op_e5: @ SBC $FF
op_f5: @ SBC $FF,X
op_ed: @ SBC $FFFF
op_fd: @ SBC $FFFF,X
op_f9: @ SBC $FFFF,Y
op_e1: @ SBC ($FF,X)
op_f1: @ SBC ($FF),Y
op_85: @ STA $FF
op_95: @ STA $FF,X
op_8d: @ STA $FFFF
op_9d: @ STA $FFFF,X
op_99: @ STA $FFFF,Y
op_81: @ STA ($FF,X)
op_91: @ STA ($FF),Y
op_86: @ STX $FF
op_96: @ STX $FF,Y
op_8e: @ STX $FFFF
op_84: @ STY $FF
op_94: @ STY $FF,X
op_8c: @ STY $FFFF
op_ba: @ TSX
op_9a: @ TXS

op_xx:
        op_end 1 2
