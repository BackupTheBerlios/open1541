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

#include <autoconf.h>

#include <lpc213x.h>
#include <uart.h>
#include <timer.h>
#include <util.h>
#include <cli.h>
#include <c1541.h>
#include <mos6502.h>

static void clock_init();
static void io_init();

/*******************************************************************************
 * Do it.
 *
 ******************************************************************************/
int main()
{
    clock_init();
    uart_init();
    uart_puts("\r\nInitializing...\r\n");
    timer_init();
    io_init();
    uart_puts("Starting drive...\r\n");

    c1541_init();

    cli_init();

    for (;;)
    {
#ifdef CONFIG_GDBSIM
        uart_putdec(demon_clock());
        uart_putcrlf();
#endif
        cli_check();
    }

    return 0;
}

/*******************************************************************************
 * Init all the clocks we need.
 *
 ******************************************************************************/
static void clock_init()
{
#ifndef CONFIG_GDBSIM
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

    /* VPB runs at clock speed, divider = 1 */
    VPBDIV = VPBDIV_1;

    /* Set up MAM */
    MAMTIM = 2; /* The manual tells we have to use 3 here */;
    MAMCR  = 2;

    PINSEL0 = PINSEL0_P00_TXD0 | PINSEL0_P01_RXD0;
#endif
}

/*******************************************************************************
 * Init all GPIOs we need.
 *
 ******************************************************************************/
static void io_init()
{
    // All GPIOs are input
    REG32OFFSET(IO0, IODIR) = 0;
    REG32OFFSET(IO0, IODIR) = 0;

    // set output for LEDs
    REG32OFFSET(LED_PORT, IODIR) |= DIRTY_LED_BIT | BUSY_LED_BIT;

    // set output for IEC
    REG32OFFSET(IEC_OUT_PORT, IODIR) |= (DAT_OUT_BIT | CLK_OUT_BIT);

    // Both LEDs on (low)
    REG32OFFSET(LED_PORT, IOCLR) = (DIRTY_LED_BIT | BUSY_LED_BIT);

    // DAT, CLK released (negated)
    REG32OFFSET(IEC_OUT_PORT, IOCLR) = (DAT_OUT_BIT | CLK_OUT_BIT);
}

