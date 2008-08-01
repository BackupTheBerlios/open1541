/*
 * lpcflash - command line LPC2xxx loader
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * Derived from:
 * LPC 2000 Loader (c) 2004, PJRC.COM, LLC, <paul@pjrc.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "uuencode.h"


unsigned int sum=0;



void cksum(const char *str)
{
	int num, i;
	unsigned char data[256];

	if (str == NULL) return;
	num = uudecode(str, data, sizeof(data));
	for (i=0; i<num; i++) {
		sum += data[i];
	}

}


int main()
{
	char buf[4096];

	while (!feof(stdin)) {
		fgets(buf, sizeof(buf), stdin);
		if (strcmp(buf, "\n") == 0) break;
		cksum(buf);
	}
	printf("sum = %u\n", sum);

	return 0;
}





