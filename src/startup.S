/*
 * startup.S - The ARM vector table and startup code
 *
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

#include <lpc213x.h>
#include <arm7tdmi.h>

#define UND_STACK_SIZE  4
#define ABT_STACK_SIZE  4
#define FIQ_STACK_SIZE  128
#define IRQ_STACK_SIZE  128
#define SVC_STACK_SIZE  4
/* the rest of the stack segment is for SYS mode */


        .text
        .code 32
        .align 2

@ ARM Exception Vectors
vectors:
reset:
        b   _begin

undefined_instr:
        b   undefined_instr

swi:
        mov pc, lr

prefetch_abort:
        b   prefetch_abort

data_abort:
        b   data_abort

@ reserved:
        nop

irq:
        b   irq

fiq:
#include "mos6502/mos6502_fiq.S"


/*******************************************************************************
 *
 * Initialize the system and call main()
 *
 ******************************************************************************/
        .global _begin
_begin:
        /* Set up stack pointers for all CPU modes */

        ldr r0, =_stack_top
        msr cpsr_c, #MODE_UND | PSR_I | PSR_F
        mov sp, r0
        sub r0, r0, #UND_STACK_SIZE

        msr cpsr_c, #MODE_ABT | PSR_I | PSR_F
        mov sp, r0
        sub r0, r0, #ABT_STACK_SIZE

        msr cpsr_c, #MODE_FIQ | PSR_I | PSR_F
        mov sp, r0
        sub r0, r0, #FIQ_STACK_SIZE

        msr cpsr_c, #MODE_IRQ | PSR_I | PSR_F
        mov sp, r0
        sub r0, r0, #IRQ_STACK_SIZE

        msr cpsr_c, #MODE_SVC | PSR_I | PSR_F
        mov sp, r0
        sub r0, r0, #SVC_STACK_SIZE

        @ leave the CPU in system mode with IRQ and FIQ enabled
        msr cpsr_c, #MODE_SYS
        mov sp, r0

        /* copy initialized data segment to RAM */
        ldr   r1, =_data_lma
        ldr   r2, =_data_vma
        ldr   r3, =_end_data_vma
1:
        cmp   r2, r3
        ldrlo r0, [r1], #4
        strlo r0, [r2], #4
        blo   1b

        /* fill BSS segment with 0 */
        mov r0, #0
        ldr r1, =_bss_vma
        ldr r2, =_end_bss_vma
2:
        cmp r1, r2
        strlo r0, [r1], #4
        blo 2b

        b   main
