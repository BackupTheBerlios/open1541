/*
 * lpc213x.h - Definitions for the ARM7TDMI processor
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

#ifndef LPC213X_H
#define LPC213X_H

#ifdef __ASSEMBLER__
# define REG32(x) x
#else
# define REG32(x) (*(volatile unsigned long*) x)
#endif

/* PLL */

#define PLLCON  REG32(0xE01FC080)
#define PLLCFG  REG32(0xE01FC084)
#define PLLSTAT REG32(0xE01FC088)
#define PLLFEED REG32(0xE01FC08C)

#define PLLCON_PLLE (1 << 0)
#define PLLCON_PLLC (1 << 1)

#define PLLCFG_PSEL_1 (0 << 5)
#define PLLCFG_PSEL_2 (1 << 5)
#define PLLCFG_PSEL_4 (2 << 5)
#define PLLCFG_PSEL_8 (3 << 5)

#define PLLSTAT_PLLE  (1 << 8)
#define PLLSTAT_PLLC  (1 << 9)
#define PLLSTAT_PLOCK (1 << 10)

/* VPB divider */

#define VPBDIV  REG32(0xE01FC100)

#define VPBDIV_4  0
#define VPBDIV_1  1
#define VPBDIV_2  2

/* MAM */
#define MAMCR   REG32(0xE01FC000)
#define MAMTIM  REG32(0xE01FC004)

/* PINSEL */

#define PINSEL0 REG32(0xE002C000)
#define PINSEL1 REG32(0xE002C004)
#define PINSEL2 REG32(0xE002C014)

#define PINSEL0_P00_GPIO    (0 << 0)
#define PINSEL0_P00_TXD0    (1 << 0)
#define PINSEL0_P00_PWM1    (2 << 0)
#define PINSEL0_P01_GPIO    (0 << 2)
#define PINSEL0_P01_RXD0    (1 << 2)
#define PINSEL0_P01_PWM3    (2 << 2)
#define PINSEL0_P01_EINT0   (3 << 2)
#define PINSEL0_P02_GPIO    (0 << 4)
#define PINSEL0_P02_SCL0    (1 << 4)
#define PINSEL0_P02_CAP00   (2 << 4)
#define PINSEL0_P03_GPIO    (0 << 6)
#define PINSEL0_P03_SDA0    (1 << 6)
#define PINSEL0_P03_MATCH00 (2 << 6)
#define PINSEL0_P03_EINT1   (3 << 6)
#define PINSEL0_P04_GPIO    (0 << 8)
#define PINSEL0_P04_SCK0    (1 << 8)
#define PINSEL0_P04_CAP01   (2 << 8)
#define PINSEL0_P04_AD06    (3 << 8)
#define PINSEL0_P05_GPIO    (0 << 10)
#define PINSEL0_P05_MISO0   (1 << 10)
#define PINSEL0_P05_MATCH01 (2 << 10)
#define PINSEL0_P05_AD07    (3 << 10)
#define PINSEL0_P06_GPIO    (0 << 12)
#define PINSEL0_P06_MOSI0   (1 << 12)
#define PINSEL0_P06_CAP02   (2 << 12)
#define PINSEL0_P06_AD10    (3 << 12)
#define PINSEL0_P07_GPIO    (0 << 14)
#define PINSEL0_P07_SSEL0   (1 << 14)
#define PINSEL0_P07_PWM2    (2 << 14)
#define PINSEL0_P07_EINT2   (3 << 14)
//#define PINSEL0_P00_    (0 << 0)

/* GPIO */

#define IO0PIN  REG32(0xE0028000)
#define IO0SET  REG32(0xE0028004)
#define IO0DIR  REG32(0xE0028008)
#define IO0CLR  REG32(0xE002800C)

#define IO1PIN  REG32(0xE0028010)
#define IO1SET  REG32(0xE0028014)
#define IO1DIR  REG32(0xE0028018)
#define IO1CLR  REG32(0xE002801C)

/* UART0 */

#define U0RBR  REG32(0xE000C000)
#define U0THR  REG32(0xE000C000)
#define U0DLL  REG32(0xE000C000)
#define U0DLM  REG32(0xE000C004)
#define U0IER  REG32(0xE000C004)
#define U0IIR  REG32(0xE000C008)
#define U0FCR  REG32(0xE000C008)
#define U0LCR  REG32(0xE000C00C)
#define U0LSR  REG32(0xE000C014)
#define U0SCR  REG32(0xE000C01C)
#define U0TER  REG32(0xE000C030)

#define U0FCR_FIFOENA   (1 << 0)
#define U0FCR_RXFFRESET (1 << 1)
#define U0FCR_TXFFRESET (1 << 2)
#define U0FCR_RXTRIGGER_SHIFT 6

#define U0LCR_WLENGTH_5 0
#define U0LCR_WLENGTH_6 1
#define U0LCR_WLENGTH_7 2
#define U0LCR_WLENGTH_8 3
#define U0LCR_NSTOPBITS (1 << 2)
#define U0LCR_PARITYENA (1 << 3)
#define U0LCR_EVENPAR   (1 << 4)
#define U0LCR_STICKYPAR (1 << 5)
#define U0LCR_BREAK     (1 << 6)
#define U0LCR_DLAB      (1 << 7)

#define U0LSR_RDR       (1 << 0)
#define U0LSR_OE        (1 << 1)
#define U0LSR_PE        (1 << 2)
#define U0LSR_BI        (1 << 4)
#define U0LSR_THRE      (1 << 5)
#define U0LSR_TEMT      (1 << 6)
#define U0LSR_RXFE      (1 << 7)

#define U0TER_TXEN      (1 << 7)

/* Timer 0 */
#define T0IR            REG32(0xE0004000)
#define T0TCR           REG32(0xE0004004)
#define T0TC            REG32(0xE0004008)
#define T0PR            REG32(0xE000400C)
#define T0PC            REG32(0xE0004010)
#define T0MCR           REG32(0xE0004014)
#define T0MR0           REG32(0xE0004018)
#define T0MR1           REG32(0xE000401C)
#define T0MR2           REG32(0xE0004020)
#define T0MR3           REG32(0xE0004024)
#define T0CCR           REG32(0xE0004028)
#define T0CR0           REG32(0xE000402C)
#define T0CR1           REG32(0xE0004030)
#define T0CR2           REG32(0xE0004034)
#define T0CR3           REG32(0xE0004038)
#define T0EMR           REG32(0xE000403C)
#define T0CTCR          REG32(0xE0004070)

/* Timer 1 */
#define T1IR            REG32(0xE0008000)
#define T1TCR           REG32(0xE0008004)
#define T1TC            REG32(0xE0008008)
#define T1PR            REG32(0xE000800C)
#define T1PC            REG32(0xE0008010)
#define T1MCR           REG32(0xE0008014)
#define T1MR0           REG32(0xE0008018)
#define T1MR1           REG32(0xE000801C)
#define T1MR2           REG32(0xE0008020)
#define T1MR3           REG32(0xE0008024)
#define T1CCR           REG32(0xE0008028)
#define T1CR0           REG32(0xE000802C)
#define T1CR1           REG32(0xE0008030)
#define T1CR2           REG32(0xE0008034)
#define T1CR3           REG32(0xE0008038)
#define T1EMR           REG32(0xE000803C)
#define T1CTCR          REG32(0xE0008070)

#define TTCR_CTRENA     (1 << 0)
#define TTCR_CTRRESET   (1 << 1)

#define TIR_MR0         (1 << 0)
#define TIR_MR1         (1 << 1)
#define TIR_MR2         (1 << 2)
#define TIR_MR3         (1 << 3)
#define TIR_CR0         (1 << 4)
#define TIR_CR1         (1 << 5)
#define TIR_CR2         (1 << 6)
#define TIR_CR3         (1 << 7)

#define TMCR_MR0I       (1 << 0)
#define TMCR_MR0R       (1 << 1)
#define TMCR_MR0S       (1 << 2)
#define TMCR_MR1I       (1 << 3)
#define TMCR_MR1R       (1 << 4)
#define TMCR_MR1S       (1 << 5)
#define TMCR_MR2I       (1 << 6)
#define TMCR_MR2R       (1 << 7)
#define TMCR_MR2S       (1 << 8)
#define TMCR_MR3I       (1 << 9)
#define TMCR_MR3R       (1 << 10)
#define TMCR_MR3S       (1 << 11)

/* VIC */
#define VICIRQSTATUS    REG32(0xFFFFF000)
#define VICFIQSTATUS    REG32(0xFFFFF004)
#define VICRAWINTR      REG32(0xFFFFF008)
#define VICINTSELECT    REG32(0xFFFFF00C)
#define VICINTENABLE    REG32(0xFFFFF010)
#define VICINTENCLR     REG32(0xFFFFF014)
#define VICSOFTINT      REG32(0xFFFFF018)
#define VICSOFTINTCLEAR REG32(0xFFFFF01C)
#define VICPROTECTION   REG32(0xFFFFF020)
#define VICVECTADDR     REG32(0xFFFFF030)
#define VICDEFVECTADDR  REG32(0xFFFFF034)
#define VICVECTADDR0    REG32(0xFFFFF100)
#define VICVECTADDR1    REG32(0xFFFFF104)
#define VICVECTADDR2    REG32(0xFFFFF108)
#define VICVECTADDR3    REG32(0xFFFFF10C)
#define VICVECTADDR4    REG32(0xFFFFF110)
#define VICVECTADDR5    REG32(0xFFFFF114)
#define VICVECTADDR6    REG32(0xFFFFF118)
#define VICVECTADDR7    REG32(0xFFFFF11C)
#define VICVECTADDR8    REG32(0xFFFFF120)
#define VICVECTADDR9    REG32(0xFFFFF124)
#define VICVECTADDR10   REG32(0xFFFFF128)
#define VICVECTADDR11   REG32(0xFFFFF12C)

#define VICINT_WDT        (1 << 0)
#define VICINT_ARMCORE0   (1 << 2)
#define VICINT_ARMCORE1   (1 << 3)
#define VICINT_TIMER0     (1 << 4)
#define VICINT_TIMER1     (1 << 5)
#define VICINT_UART0      (1 << 6)
#define VICINT_UART1      (1 << 7)
#define VICINT_PWM0       (1 << 8)
#define VICINT_I2C0       (1 << 9)
#define VICINT_SPI0       (1 << 10)
#define VICINT_SSP        (1 << 11)
#define VICINT_SPI1       (1 << 11)
#define VICINT_PLL        (1 << 12)
#define VICINT_RTC        (1 << 13)
#define VICINT_EINT0      (1 << 14)
#define VICINT_EINT1      (1 << 15)
#define VICINT_EINT2      (1 << 16)
#define VICINT_EINT3      (1 << 17)
#define VICINT_AD0        (1 << 18)
#define VICINT_I2C1       (1 << 19)
#define VICINT_BOD        (1 << 20)
#define VICINT_AD1        (1 << 21)

#endif /* LPC213X_H */