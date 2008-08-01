/*
 * Taken from dietlibc
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

#include <string.h>

/* gcc is broken and has a non-SUSv2 compliant internal prototype.
 * This causes it to warn about a type mismatch here.  Ignore it. */
int strncmp(const char *s1, const char *s2, size_t n)
{
    const unsigned char* a = (const unsigned char*) s1;
    const unsigned char* b = (const unsigned char*) s2;
    const unsigned char* fini = a + n;
    while (a < fini)
    {
        register int res= *a - *b;
        if (res) return res;
        if (!*a) return 0;
        ++a;
        ++b;
    }
    return 0;
}
