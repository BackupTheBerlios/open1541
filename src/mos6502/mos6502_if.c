/*
 * mos6502 - a 6502 emulator
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
    uart_puthex_padded(4, regs.pc);
    uart_putc(' ');
    uart_puthex_padded(2, regs.a);
    uart_putc(' ');
    uart_puthex_padded(2, regs.x);
    uart_putc(' ');
    uart_puthex_padded(2, regs.y);
    uart_putc(' ');
    uart_puthex_padded(2, regs.sp);
    uart_putc(' ');
    uart_putc(regs.flags & PSR_N ? 'N' : '-');
    uart_putc(regs.flags & PSR_V ? 'V' : '-');
    uart_puts("----");
    uart_putc(regs.flags & PSR_Z ? 'Z' : '-');
    uart_putc(regs.flags & PSR_C ? 'C' : '-');

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

#if CONFIG_BREAKPOINTS > 0
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
