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

/* If this code fails to build, please provide at least the following
 * information when requesting (free) technical support.
 * 
 * 1: Complete copy of all messages during the build.
 * 2: Output of "gtk-config --version"
 * 3: Output of "gtk-config --libs"
 * 4: Output of "gtk-config --cflags"
 * 5: Output of "uname -a"
 * 6: Version of GTK installed... eg, type: ls -l /lib/libgtk*
 * 7: Other info... which linux distribution, version, other software
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "settings.h"

static void usage(const char* prog_name);

static char* file;
static char* port = "/dev/ttyS0";
static long  baud = 38400;
static long  xtal = 10000;


int init_settings(int argc, char** argv)
{
	int i;

	if (argc == 1) {
		usage(argv[0]);
		return -1;
	}

	for (i = 1; i < argc; i++) {
		if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
			usage(argv[0]);
			return -1;
		}
		else if (strcmp(argv[i], "--port") == 0 || strcmp(argv[i], "-p") == 0) {
			if (i + 1 >= argc) {
				fprintf(stderr, "Error: Missing port name after %s\n", argv[i]);
				return -1;
			}
			else {
				i++;
				port = argv[i];
			}
		}
		else if (strcmp(argv[i], "--baud") == 0 || strcmp(argv[i], "-b") == 0) {
			if (i + 1 >= argc) {
				fprintf(stderr, "Error: Missing baud rate after %s\n", argv[i]);
				return -1;
			}
			else {
				i++;
				if (sscanf(argv[i], "%ld", &baud) != 1) {
					fprintf(stderr, "Invalid baud rate\n");
					return -1;
				}
			}
		}
		else if (strcmp(argv[i], "--xtal") == 0 || strcmp(argv[i], "-x") == 0) {
			if (i + 1 >= argc) {
				fprintf(stderr, "Error: Missing xtal frequency after %s\n", argv[i]);
				return -1;
			}
			else {
				i++;
				if (sscanf(argv[i], "%ld", &xtal) != 1) {
					fprintf(stderr, "Invalid xtal frequency\n");
					return -1;
				}
				if (xtal < 10000 || xtal > 250000) {
					printf("Warning: xtal frequency out of range (10000 to 25000), "
					       "continuing anyway! (hope you know what you're doing)\r\n");
				}
			}
		}
		else {
			if (file) {
				fprintf(stderr, "Too many files or unknown argument \"%s\", use %s --help to find out more.\n",
					argv[i], argv[0]);
				return -1;
			}
			else {
				file = argv[i];
			}
		}
	}

	if (!file) {
		fprintf(stderr, "Missing file name.\n");
		return -1;
	}

	return 0;
}


const char * file_setting(void)
{
	return file;
}

const char * port_setting(void)
{
	return port;
}

long baud_setting(void)
{
	return baud;
}

long xtal_setting(void)
{
	return xtal;
}


static void usage(const char* prog_name) {
	printf("\n%s - LPC21xx ISP\n", prog_name);
	printf("\nUsage: %s [options] hexfile\n\n", prog_name);
	printf(" --port | -p\tSerial port (default %s)\n", port);
	printf(" --baud | -b\tBaud rate (default %ld)\n", baud);
	printf(" --xtal | -x\tCrystal frequency in kHz (default %ld)\n\n", xtal);
}
