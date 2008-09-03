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

#include <lpc213x.h>
#include <uart.h>
#include <timer.h>
#include <util.h>
#include <cli.h>
#include <mos6502.h>
#include <c1541.h>
#include <autoconf.h>

static void init_clocks();

/*******************************************************************************
 * Do it.
 *
 ******************************************************************************/
int main()
{
    init_clocks();
    uart_init();
    uart_puts("\r\nInitializing...\r\n");
    timer_init();

    uart_puts("Starting drive...\r\n");

    c1541_init();

    cli_init();

    REG32OFFSET(DIRTY_LED_PORT, IODIR) |= 1 << DIRTY_LED_PIN;
    REG32OFFSET(DIRTY_LED_PORT, IOCLR)  = 1 << DIRTY_LED_PIN;

    //REG32OFFSET(BUSY_LED_PORT, IODIR) |= 1 << BUSY_LED_PIN;
    //REG32OFFSET(BUSY_LED_PORT, IOCLR)  = 1 << BUSY_LED_PIN;

    for (;;)
    {
        cli_check();
    }

    return 0;
}

/*******************************************************************************
 * Init all the clocks we need.
 *
 ******************************************************************************/
static void init_clocks()
{
#if CCLK != XTAL
    /* PLL initialization */
    PLLCFG = ((CCLK / XTAL) - 1) | PLLCFG_PSEL_2;
    PLLCON = PLLCON_PLLE;
    PLLFEED = 0xAA;
    PLLFEED = 0x55;
    while(!(PLLSTAT & PLLSTAT_PLOCK))
    {;}
    PLLCON = PLLCON_PLLE | PLLCON_PLLC;
    PLLFEED=0xAA;
    PLLFEED=0x55;
#endif

    /* VPB runs at clock speed, divider = 1 */
    VPBDIV = VPBDIV_1;

    /* Set up MAM */
    MAMTIM = 2; /* The manual tells we have to use 3 here */;
    MAMCR  = 2;

    PINSEL0 = PINSEL0_P00_TXD0 | PINSEL0_P01_RXD0;
}
