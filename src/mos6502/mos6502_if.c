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
#include <string.h>
#include <autoconf.h>
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

    uart_puts("      TIME  PC  AC XR YR SP NV#BDIZC\r\n");
    //         1234567890 1234 11 22 33 44 ********
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
    uart_puthex_padded(2, regs.sp);
    uart_putc(' ');
    uart_putc(regs.pc & PSR_N ? 'N' : '-');
    uart_putc(regs.pc & PSR_V ? 'V' : '-');
    uart_puts("----");
    uart_putc(regs.pc & PSR_Z ? 'Z' : '-');
    uart_putc(regs.pc & PSR_C ? 'C' : '-');

    uart_putcrlf();
}

/*******************************************************************************
 * Print a hexdump of client memory from <start> to <stop> (excluded) to UART.
 *
 ******************************************************************************/
void mos6502_dump_mem(uint16_t start, uint16_t stop)
{
    uint8_t c;
    char text[17];
    unsigned llen;

    /* exclude "stop" from output */
    while (start < stop)
    {
        memset(text, 0, sizeof(text));
        llen = 16;
        uart_puthex_padded(4, start);
        uart_puts(": ");
        while (llen && start < stop)
        {
            c = mos6502_read_mem(start);
            uart_puthex_padded(2, c);
            uart_putc(' ');

            if (c < ' ' || c > 126)
                c = '.';
            text[16 - llen] = c;

            if ((--llen & 3) == 0)
                uart_putc(' ');
            start++;
        }
        uart_putc(' ');
        uart_puts(text);
        uart_putcrlf();
    }
}

/*******************************************************************************
 * Fill <from>  to <to> (included) with <val>.
 *
 ******************************************************************************/
void mos6502_fill_mem(uint16_t from, uint16_t to, uint8_t val)
{
    while (from <= to)
    {
        mos6502_write_mem(from++, val);
    }
}

#ifdef CONFIG_BREAKPOINTS
/*******************************************************************************
 * Print a list of breakpoints set.
 *
 ******************************************************************************/
void mos6502_show_breakpoints(void)
{
    uint32_t  old_flags;
    uint16_t* p;

    old_flags = disable_irqs();
    p = &mos6502_bp;
    while (*p)
    {
        uart_puthex_padded(4, *p);
        uart_putcrlf();
        p++;
    }

    restore_flags(old_flags);
}

/*******************************************************************************
 * Set a breakpoint at addr. If there is a breakpoint at this address already,
 * let the call succeed without setting another one.
 * Return 1 on success, 0 otherwise.
 *
 ******************************************************************************/
int mos6502_set_breakpoint(uint16_t addr)
{
    uint32_t  old_flags;
    int i;
    int ret = 0;

    old_flags = disable_irqs();
    for (i = 0; i < CONFIG_BREAKPOINTS; i++)
    {
        // breakpoint already there?
        if ((&mos6502_bp)[i] == addr)
        {
            ret = 1;
            break;
        }

        // end of list reached?
        if ((&mos6502_bp)[i] == 0)
        {
            (&mos6502_bp)[i] = addr;
            ret = 1;
            break;
        }
    }

    restore_flags(old_flags);
    return ret;
}

/*******************************************************************************
 * Remove a breakpoint at addr.
 *
 ******************************************************************************/
void mos6502_rm_breakpoint(uint16_t addr)
{
    uint32_t old_flags;
    int i;

    i = 0;
    old_flags = disable_irqs();

    while ((&mos6502_bp)[i])
    {
        if ((&mos6502_bp)[i] == addr)
        {
            memmove(&mos6502_bp + i, &mos6502_bp + i + 1,
                    sizeof(mos6502_bp) * (CONFIG_BREAKPOINTS - i) );
        }
        i++;
    }

    restore_flags(old_flags);
}
#endif /* CONFIG_BREAKPOINTS */
