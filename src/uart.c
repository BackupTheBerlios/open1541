/*
 * uart.c - Poor mans debugging interface
 *
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
#include <uart.h>

static inline void uart_puthex_digit(int digit);


/*******************************************************************************
 * Init everything needed to get the rest of the UART functions running.
 *
 ******************************************************************************/
void uart_init()
{
    U0LCR = U0LCR_DLAB | U0LCR_WLENGTH_8;
    U0DLM = ((PCLK / 16) / CONFIG_UART_BAUDRATE) >> 8;
    U0DLL = ((PCLK / 16) / CONFIG_UART_BAUDRATE);
    U0LCR = U0LCR_WLENGTH_8;

    U0FCR = U0FCR_FIFOENA;
}

/*******************************************************************************
 * Print the given character to UART. Wait if the FIFO is full.
 *
 ******************************************************************************/
void uart_putc(char c)
{
    // wait for space in TX FIFO
    while (!(U0LSR & U0LSR_THRE))
    {;}

    U0THR = c;
}

/*******************************************************************************
 * Print the given character n times to UART. Wait if the FIFO is full.
 *
 ******************************************************************************/
void uart_putnc(int n, char c)
{
    int i;
    for (i = 0; i < n; i++)
    {
        uart_putc(c);
    }
}

/*******************************************************************************
 * Get a character from UART if one is buffered. Returns -1 if nothing is 
 * buffered.
 *
 ******************************************************************************/
int uart_getc(void)
{
    if (U0LSR & U0LSR_RDR)
        return U0RBR & 0xff;
    else
        return -1;
}

/*******************************************************************************
 * Print CR LF to UART.
 *
 ******************************************************************************/
void uart_putcrlf()
{
    uart_putc(13);
    uart_putc(10);
}

/*******************************************************************************
 * Print the given string to UART.
 *
 ******************************************************************************/
void uart_puts(char* text)
{
    char ch;

    while ((ch = *text++))
    {
        uart_putc(ch);
    }
}

/*******************************************************************************
 * Print the given number in hex format. Fill up leading '0' on the left side
 * to get at least *size* digits.
 * If more then *size* digits are needed, use more.
 *
 ******************************************************************************/
void uart_puthex_padded(int size, uint32_t num)
{
    int i;
    uint32_t tmp;

    // always print at laest one digit
    if (size < 1)
        size = 1;

    for (i = 8; i != 0; i--)
    {
        tmp = (num & 0xf0000000) >> 28;

        if (tmp || i <= size)
        {
            uart_puthex_digit(tmp);

            // a digit != 0 was found, print all digits from now
            size = i;
        }

        num <<= 4;
    }
}

/*******************************************************************************
 * Print the given number in hex format. Use as many digits as are needed,
 *
 ******************************************************************************/
void uart_puthex(uint32_t num)
{
    uart_puthex_padded(0, num);
}

/*******************************************************************************
 * Print the given number in decimal format. Fill up leading spaces on the left 
 * side to get at least *size* digits.
 * If more then *size* digits are needed, use more.
 *
 ******************************************************************************/
void uart_putdec_padded(int size, uint32_t num)
{
    char *p, buf[11];
    int digits;

    // calculate all digits, put them in reverse order into buf
    p = buf;
    if (num == 0)
        *p++ = 0; // force 0 to be printed
    else
    {
        while (num != 0)
        {
            *p++ = num % 10;
            num /= 10;
        }
    }

    // print leading spaces
    digits = p - buf;
    while (digits++ < size)
        uart_putc(' ');

    // print the digits
    while (p != buf)
        uart_putc('0' + *--p);
}

/*******************************************************************************
 * Print the given number in decimal format. Use as many digits as are needed,
 *
 ******************************************************************************/
void uart_putdec(uint32_t num)
{
    uart_putdec_padded(0, num);
}

/*******************************************************************************
 * Print one hex digit.
 *
 * digit    0..15, other values will break everything
 *
 ******************************************************************************/
static inline void uart_puthex_digit(int digit)
{
    // yes, this is smaller on ARM than if/else
    static const char digits[] = "0123456789abcdef";

    uart_putc(digits[digit]);
}
