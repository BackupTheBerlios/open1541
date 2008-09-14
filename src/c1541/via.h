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
#ifndef VIA_H
#define VIA_H

#include <autoconf.h>

#define VIA1_BASE       0x1800
#define VIA2_BASE       0x1c00

/* MOS 6522 registers */
#define VIA_PRB         0x00    /* Port B */
#define VIA_PRA         0x01    /* Port A */
#define VIA_DDRB        0x02    /* Data direction register for port B */
#define VIA_DDRA        0x03    /* Data direction register for port A */

#define VIA_T1CL        0x04    /* Timer 1 count low */
#define VIA_T1CH        0x05    /* Timer 1 count high */
#define VIA_T1LL        0x06    /* Timer 1 latch low */
#define VIA_T1LH        0x07    /* Timer 1 latch high */
#define VIA_T2CL        0x08    /* Timer 2 count low - read only */
#define VIA_T2LL        0x08    /* Timer 2 latch low - write only */
#define VIA_T2CH        0x09    /* Timer 2 latch/count high */

#define VIA_SR          0x0a    /* Serial port shift register */
#define VIA_ACR         0x0b    /* Auxiliary control register */
#define VIA_PCR         0x0c    /* Peripheral control register */

#define VIA_IFR         0x0d    /* Interrupt flag register */
#define VIA_IER         0x0e    /* Interrupt control register */
#define VIA_PRA_NHS     0x0f    /* Port A with no handshake */

#define VIA_REG_SIZE    0x10    /* Number of VIA registers */

/* Interrupt Masks  */
#define VIA_IM_IRQ      0x80    /* Control Bit */
#define VIA_IM_T1       0x40    /* Timer 1 underflow */
#define VIA_IM_T2       0x20    /* Timer 2 underflow */
#define VIA_IM_CB1      0x10    /* Handshake */
#define VIA_IM_CB2      0x08    /* Handshake */
#define VIA_IM_SR       0x04    /* Shift Register completion */
#define VIA_IM_CA1      0x02    /* Handshake */
#define VIA_IM_CA2      0x01    /* Handshake */

#ifdef __ASSEMBLER__

#if CONFIG_VIA_TRACES
.macro via_report_access_r
        push    {lr}
        mov     r0, #'r'
        bl      via_report_access
        pop     {lr}
.endm

.macro via_report_access_w
        push    {lr}
        mov     r0, #'w'
        bl      via_report_access
        pop     {lr}
.endm
#else
.macro via_report_access_r
.endm
.macro via_report_access_w
.endm
#endif

#endif /* ASSEMBLY */
#endif /* VIA_H */
