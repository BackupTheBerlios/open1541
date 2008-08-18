/*
 * util.c - utility functions
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

#include <util.h>
#include <string.h>

/*******************************************************************************
 * Convert a hexadecimal digit to int. Return -1 if it is an invalid digit.
 *
 ******************************************************************************/
int util_hdigit2i(int ch)
{
    ch |= 0x20;
    if (ch >= '0' && ch <= '9')
        return ch - '0';
    /* convert to lower case */
    if (ch >= 'a' && ch <= 'f')
        return 10 + ch - 'a';
    return -1;
}

/*******************************************************************************
 * Parse a hexadecimal number from the given string. Return the number
 * and a pointer behind the parsed string. Parsing is stopped at '\0' or ' ',
 * Leading spaces are skipped. Returns NULL on errors or if no digit found.
 *
 ******************************************************************************/
const char* util_parse_hex(const char* str, unsigned* v)
{
    int d = -1;

    /* skip leading spaces */
    while (*str == ' ')
        str++;

    *v = 0;
    while (*str && *str != ' ')
    {
        d = util_hdigit2i(*str++);

        if (d < 0)
            break;

        *v = *v * 16 + d;
    }

    return d >= 0 ? str : NULL;
}
