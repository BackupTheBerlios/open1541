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

#include <autoconf.h>

#include <lpc213x.h>

#include <via.h>
#include <mos6502_macros.S>

MACH_DATA_DECLARE = 1
#include <mach_data.S>


/*******************************************************************************
 * Report VIA register accesses
 * input: r0 = 'w' for write, r0 = 'r' for read
 *
 ******************************************************************************/
        .global via_report_access
via_report_access:
        push    {r1 - r5, lr}

        mov     r4, m_addr          @ save regs
        mov     r5, m_data

        bl      uart_putc           @ 'w' or 'r'

        mov     r0, #':'
        bl      uart_putc

        pc_host_to_client r0
        bl      uart_puthex

        mov     r0, #':'
        bl      uart_putc

        mov     r0, r4              @ address
        bl      uart_puthex

        mov     r0, #'='
        bl      uart_putc

        mov     r0, r5              @ data
        bl      uart_puthex

        bl      uart_putcrlf

        @ ugly hack: delay the CPU emulation so it won't stop
        add     m_t, m_t, #0x10000  @ 65 ms

        pop     {r1 - r5, pc}
