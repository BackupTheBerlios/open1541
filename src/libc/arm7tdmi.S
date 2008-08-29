/*
 * open1541.c - The main program
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

#include <arm7tdmi.h>

/*******************************************************************************
 * Disable all IRQs.
 * Return the previous processor flags in r0.
 *
 ******************************************************************************/
        .global disable_irqs
disable_irqs:
        @ remember old processor and interrupt state
        mrs     r0, cpsr

        @ disable IRQs so we won't be disturbed
        orr r1, r0, #(PSR_I | PSR_F)
        msr cpsr_c, r1

        @ return
        mov pc, lr


/*******************************************************************************
 * Restore the processor flags (CPSR_C) from r0.
 *
 ******************************************************************************/
        .global restore_flags
restore_flags:
        @ restore old processor and interrupt state, return
        msr cpsr_c, r0
        mov pc, r14
