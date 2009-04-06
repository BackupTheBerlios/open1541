/*
 * VIA emulation
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
#define VIA_IER         0x0e    /* Interrupt enable register */
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

#endif /* VIA_H */
