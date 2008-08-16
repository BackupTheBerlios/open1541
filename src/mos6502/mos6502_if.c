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

#include <stdint.h>
#include <uart.h>
#include <arm7tdmi.h>
#include <lpc213x.h>
#include "mos6502.h"

/*******************************************************************************
 * Initialize the 6502 processor emulation.
 *
 ******************************************************************************/
void mos6502_reset(void)
{
    // Disable timer IRQ
    VICINTENABLE &= ~VICINT_TIMER0;

    // Enable FIQ on Timer 0 Match 0
    T0MCR |= TMCR_MR0I;
    VICINTSELECT |= VICINT_TIMER0;

    mos6502_reg_init();

    // Enable timer IRQ
    VICINTENABLE |= VICINT_TIMER0;
}

/*******************************************************************************
 * Show the registers on UART.
 *
 ******************************************************************************/
void mos6502_dump_regs(void)
{
    mos6502_regs_t regs;

    mos6502_store_regs(&regs);

    uart_puts("      TIME  PC  AC XR YR NV#BDIZC\r\n");
    //         1234567890 1234 11 22 33 ********
    uart_putdec_padded(10, regs.time);
    uart_putc(' ');
    uart_puthex_padded(4, regs.pc & 0xffff);
    uart_putc(' ');
    uart_puthex_padded(2, regs.a);
    uart_putc(' ');
    uart_puthex_padded(2, regs.x);
    uart_putc(' ');
    uart_puthex_padded(2, regs.y);
    uart_putc(' ');
    uart_putc(regs.pc & PSR_N ? 'N' : '-');
    uart_putc(regs.pc & PSR_V ? 'V' : '-');
    uart_puts("----");
    uart_putc(regs.pc & PSR_Z ? 'Z' : '-');
    uart_putc(regs.pc & PSR_C ? 'C' : '-');

    uart_putcrlf();
}

/*******************************************************************************
 * Print a hexdump of client memory to UART.
 *
 ******************************************************************************/
void mos6502_dump_mem(uint16_t start, uint16_t stop)
{
    unsigned llen;

    /* exclude "stop" from output */
    while (start < stop)
    {
        llen = 16;
        uart_puthex_padded(4, start);
        uart_puts(": ");
        while (llen-- && start < stop)
        {
            uart_puthex_padded(2, mos6502_read_mem(start));
            uart_putc(' ');
            if ((llen & 3) == 0)
                uart_putc(' ');
            start++;
        }
        uart_putcrlf();
    }
}
