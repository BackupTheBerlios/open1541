/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 * parts (c) 2007,2008  Ingo Korb <ingo@akana.de>
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
#include <autoconf.h>

        .global util_benchmark
util_benchmark:
        @ r0 loop counter
        @ r1 points to timer register
        @ r2 timer start value
        @ r3 scratch
        ldr r1, =T0TC
        mov r0, #0          @ loop counter
        ldr r2, [r1]        @ load timer start value
1:
        add r0, r0, #1      @ inc loop counter
        ldr r3, [r1]        @ load current time
        sub r3, r3, r2      @ delta T
        cmp r3, #0x80000    @ about 524 ms
        blo 1b

        mov pc, lr

/*******************************************************************************
 * Wait for the number of microseconds in R0. This code needs timer 0 to be
 * running continuously at 1 MHz.
 *
 ******************************************************************************/
        .global udelay
udelay:
        @ r0 number of microseconds
        @ r1 points to timer register
        @ r2 timer start value
        @ r3 scratch
        ldr r1, =T0TC
        ldr r2, [r1]        @ load timer start value
1:
        ldr r3, [r1]        @ load current time
        sub r3, r3, r2      @ delta T
        cmp r3, r0          @ time over?
        blo 1b

        mov pc, lr
