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

void *memcpy (void *dst, const void *src, size_t n)
{
    void           *res = dst;
    unsigned char  *c1, *c2;

    c1 = (unsigned char *) dst;
    c2 = (unsigned char *) src;

    while ( n-- )
        *c1++ = *c2++;

    return ( res );
}
