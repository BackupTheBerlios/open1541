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
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <sys/time.h>
#include <time.h>


#include "settings.h"
#include "lpcflash.h"
#include "download.h"
#include "serial.h"
#include "ihex.h"
#include "uuencode.h"
#include "chipinfo.h"
#include "boot.h"


// This will cause all bytes send and received to be printed as hex.
// It's a LOT of extra output, but useful for difficult debugging
// of what's _really_ being sent and received.
//#define PRINT_TX_RX_BYTES


static void download_main(int event);
static void xmit_cmd(const char *cmd, int timeout_ms);
static void mk_valid_code_vector(void);
static unsigned int sum(unsigned char *data, int num);
static long current_time_ms();


static int state=0;
static int reboot_only=0;
static char expected_echo_buf[4096];
static char *expected_echo_ptr=NULL;
static char parsed_response_buf[4096];
static char *parsed_response_ptr=NULL;
static long response_timeout=-1;


/****************************************************************/
/*								*/
/*		     Main Download Section			*/
/*								*/
/****************************************************************/

// possible states
#define IDLE			0
#define SYNC_1			1
#define SYNC_2			2
#define SYNC_3			3
#define CHIP_ID			4
#define UNLOCK			5
#define BLANK_CHECK_SECTOR	6
#define ERASE_PREPARE		7
#define ERASE_SECTOR		8
#define DOWNLOAD_CODE		9
#define XMIT_DATA		10
#define XMIT_CKSUM		11
#define WRITE_PREPARE		12
#define WRITE_SECTOR		13
#define BOOT_HARD		14
#define BOOT_SOFT		15
#define BOOT_XMIT_DATA		16
#define BOOT_XMIT_CKSUM		17
#define BOOT_RUN_CODE		18


// possible input values for "event"
#define BEGIN 1
#define RESPONSE 2
#define TIMEOUT 3
#define RETRY 4




int download_begin(void)
{
	int r;

	printf("\r\nEntering Bootloader Mode\r\n");
	hard_reset_to_bootloader();
	printf("Read \"%s\"\r\n", file_setting());
	r = read_intel_hex(file_setting());
	if (r < 0) {
		return -1;
	}
	printf("%d bytes\r\n", r);
	mk_valid_code_vector();
	state = SYNC_1;
	reboot_only = 0;
	download_main(BEGIN);
	return 0;
}

void soft_reboot_begin(void)
{
	printf("\r\nEntering Bootloader Mode\r\n");
	hard_reset_to_bootloader();
	state = SYNC_1;
	reboot_only = 1;
	download_main(BEGIN);
}

void hard_reset_to_bootloader(void)
{
	printf("Reset CPU (into bootloader)\r\n");
	set_rts(1);		// RTS (ttl level) connects to P0.14
	set_dtr(1);		// DTR (ttl level) connects to RST
	send_break_signal();	// or break detect circuit to RST
	usleep(75000);
	set_dtr(0);		// allow the CPU to run
	set_baud(baud_setting());
	usleep(40000);
}

void hard_reset_to_user_code(void)
{
	printf("Reset CPU (into user code)\r\n");
	set_rts(0);		// RTS (ttl level) connects to P0.14
	set_dtr(1);		// DTR (ttl level) connects to RST
	send_break_signal();	// or break detect circuit to RST
	usleep(75000);
	set_dtr(0);		// allow the CPU to run
	usleep(40000);
}

static void mk_valid_code_vector(void)
{
	unsigned char b[4];
	unsigned int sum=0;
	int addr;

	for (addr=0; addr<0x20; addr+=4) {
		if (addr != 0x14) {
			get_ihex_data(addr, 4, b);
			sum += (b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24));
		}
	}
	sum ^= 0xFFFFFFFF;
	sum++;
	b[0] = (sum >> 0) & 255;
	b[1] = (sum >> 8) & 255;
	b[2] = (sum >> 16) & 255;
	b[3] = (sum >> 24) & 255;
	put_ihex_data(0x14, 4, b);
}


static unsigned int sum(unsigned char *data, int num)
{
	unsigned int sum=0;

	while (num > 0) {
		sum += *data++;
		num--;
	}
	return sum;
}


static int num_lines(const char *buf)
{
	const char *p;
	int count=0;

	p = buf;
	while (p != NULL) {
		p = strstr(p, "\r\n");
		if (p != NULL) {
			count++;
			p += 2;
		}
	}
	return count;
}

void trim_crlf(char *str)
{
	char *p;
	p = strstr(str, "\r\n");
	if (p != NULL) *p = '\0';
}

void copy_boot_code_to_memory(struct chip_info_struct *chip)
{
	int i;
	unsigned char c[4];

	for (i=0; i < chip->bootprog[0]; i++) {
		c[3] = (chip->bootprog[i+1] >> 24) & 255;
		c[2] = (chip->bootprog[i+1] >> 16) & 255;
		c[1] = (chip->bootprog[i+1] >> 8) & 255;
		c[0] = (chip->bootprog[i+1]) & 255;
		put_ihex_data(i * 4, 4, c);
	}
}


#define NO_SYNC_ERR "\r\n\
ERROR: Unable to sync to baud rate.\r\n\
This probably means the LPC2xxx chip is not connected\r\n\
or it is not being reset, or P0.14 is not low after\r\n\
reset to cause it to enter the bootloader mode.\r\n\r\n\
Please check the serial port connection, make sure\r\n\
pin P0.14 is low (or tied to RTS via RS-232 level\r\n\
translator), and the chip has been reset (or reset\r\n\
is tied to DTR via RS-232 level translator).\r\n"

#define UNKNOWN_CHIP_ERROR "\r\n\
Unknown chip ID: \"%s\".\r\n\r\n\
Perhaps you have a new Philips LPC chip which does not\r\n\
have its ID string and sector map defined in this program?\r\n\
Please contact paul@pjrc.com.  Please include an exact copy\r\n\
of this message and any info about the chip and other\r\n\
hardware you may be using.  Thanks :-)\r\n"


static void download_main(int event)
{
	char buf[4096];
	unsigned char bytes[256];
	int n;
	static unsigned int cksum;
	static int retry=0;
	static int sector;		// current sector we're doing
	static int sector_offset;
	static struct chip_info_struct *chip;	// which chip
	static int current_addr, num_to_xmit, linecount;


    while (1) {
	switch (state) {
	  case SYNC_1:
		switch (event) {
		  case BEGIN:
			printf("Attempting baud sync");
			retry = 0;
		  case RETRY:
			printf(".");
			fflush(stdout);
			xmit_cmd("?", 200);
			return;
		  case RESPONSE:
			if (strcmp(parsed_response_buf, "Synchronized\r\n") == 0) {
				//printf("response: sync'd\n");
				state = SYNC_2;
				event = BEGIN;
				break;
			}
			if (strcmp(parsed_response_buf, "?") == 0) {
				//printf("response: echo only\n");
				retry++;
				if (retry > 150) {
					download_cancel(NO_SYNC_ERR); 
					return;
				}
				event = RETRY;
				usleep(30000);
				break;
			}
			snprintf(buf, sizeof(buf), "Unexpected response to sync, \"%s\"",
				parsed_response_buf);
			download_cancel(buf); 
			return;
		  case TIMEOUT:
			if (retry < 100) {
				retry++;
				event = RETRY;
				break;
			}
			download_cancel(NO_SYNC_ERR);
			return;
		}
		break;


	  case SYNC_2:
		switch(event) {
		  case BEGIN:
			xmit_cmd("Synchronized\r\n", 300);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "OK\r\n") == 0) {
				state = SYNC_3;
				event = BEGIN;
				break;
			} else {
				snprintf(buf, sizeof(buf), "Unable to complete baud sync, %s",
					parsed_response_buf);
				download_cancel(buf); 
				return;
			}
			return;
		  case TIMEOUT:
			download_cancel("No response to complete baud sync"); 
			return;
		}
		break;


	  case SYNC_3:
		switch(event) {
		  case BEGIN:
			snprintf(buf, sizeof(buf), "%ld\r\n", xtal_setting());
			xmit_cmd(buf, 300);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "OK\r\n") == 0) {
				printf("Baud sync sucessful\r\n");
				state = CHIP_ID;
				event = BEGIN;
				break;
			} else {
				snprintf(buf, sizeof(buf), "wrong response to crystal: %s",
					parsed_response_buf);
				download_cancel(buf); 
				return;
			}
			return;
		  case TIMEOUT:
			download_cancel("No response to crystal speed"); 
			return;
		}
		break;


	  case CHIP_ID:
		switch(event) {
		  case BEGIN:
			xmit_cmd("J\r\n", 300);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) < 2) return;
			if (strncmp(parsed_response_buf, "0\r\n", 3) == 0) {
				trim_crlf(parsed_response_buf+3);
				for (chip=chip_info; chip->part_number != NULL; chip++) {
					if (strcmp(parsed_response_buf+3, chip->id_string) == 0)
						break;
				}
				if (chip->part_number == NULL) {
					snprintf(buf, sizeof(buf), UNKNOWN_CHIP_ERROR,
						parsed_response_buf+3);
					download_cancel(buf);
					break;
				}
				printf("Found chip: \"%s\"\r\n", chip->part_number);
				  //download_cancel("stop here, remove this later");
				state = UNLOCK;
				event = BEGIN;
				break;
			} else {
				snprintf(buf, sizeof(buf), "wrong response to ID: %s",
					parsed_response_buf);
				download_cancel(buf); return;
			}
			return;
		  case TIMEOUT:
			download_cancel("No response to unlock command"); 
			return;
		}
		break;


	  case UNLOCK:
		switch(event) {
		  case BEGIN:
			xmit_cmd("U 23130\r\n", 300);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "0\r\n") == 0) {
				printf("Device Unlocked\r\n");
				if (reboot_only) {
					state = BOOT_SOFT;
				} else {
					state = BLANK_CHECK_SECTOR;
					printf("Erasing....\r\n");
					sector = 0;
				}
				event = BEGIN;
				break;
			} else {
				snprintf(buf, sizeof(buf), "wrong response unlock: %s",
					parsed_response_buf);
				download_cancel(buf); 
				return;
			}
			return;
		  case TIMEOUT:
			download_cancel("No response to unlock command"); 
			return;
		}
		break;

	
	  case BLANK_CHECK_SECTOR:
		switch(event) {
		  case BEGIN:
			if (sector >= chip->num_sector) {
				printf("Programming....\r\n");
				state = DOWNLOAD_CODE;
				sector = sector_offset = 0;
				event = BEGIN;
				break;
			}
			printf("  Sector %2d: ", sector);
			fflush(stdout);
			if (!bytes_within_range(chip->layout[sector].address, 
			   chip->layout[sector].address + chip->layout[sector].size - 1)) {
				printf("not used\r\n");
				sector++;
				break;
			}
			if (sector == 0) {
				// can't blank check sector 0, so always erase it
				state = ERASE_PREPARE;
				break;
			}
			snprintf(buf, sizeof(buf), "I %d %d\r\n", sector, sector);
			xmit_cmd(buf, 500);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) == 1 &&
			  strcmp(parsed_response_buf, "0\r\n") == 0) {
				printf("already blank\r\n");
				sector++;
				event = BEGIN;
				break;
			} else {
				if (num_lines(parsed_response_buf) < 3) return;
				state = ERASE_PREPARE;
				event = BEGIN;
				break;
			}
		  case TIMEOUT:
			download_cancel("No response to blank check"); 
			return;
		}
		break;



	  case ERASE_PREPARE:
		switch(event) {
		  case BEGIN:
			printf("prep, ");
			fflush(stdout);
			snprintf(buf, sizeof(buf), "P %d %d\r\n", sector, sector);
			xmit_cmd(buf, 800);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "0\r\n") == 0) {
				state = ERASE_SECTOR;
				event = BEGIN;
				break;
			} else {
				download_cancel("Unable to prep for write"); 
				return;
			}
		  case TIMEOUT:
			download_cancel("No response"); 
			return;
		}
		break;



	  case ERASE_SECTOR:
		switch(event) {
		  case BEGIN:
			printf("erase... ");
			fflush(stdout);
			snprintf(buf, sizeof(buf), "E %d %d\r\n", sector, sector);
			xmit_cmd(buf, 2500);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) < 1) return;
			if (strcmp(parsed_response_buf, "0\r\n") == 0) {
				printf("Ok\r\n");
				sector++;
				state = BLANK_CHECK_SECTOR;
				event = BEGIN;
				break;
			} else {
				printf("Error\r\n");
				download_cancel("Unable to erase flash"); 
				return;
			}
		  case TIMEOUT:
			download_cancel("No response"); 
			return;
		}
		break;



	  case DOWNLOAD_CODE:
		switch(event) {
		  case BEGIN:
			if (sector >= chip->num_sector) {
				state = BOOT_HARD;
				sector = 0;
				event = BEGIN;
				break;
			}
			printf("  Sector %2d (0x%08X-0x%08X): ", sector,
				chip->layout[sector].address + sector_offset,
				chip->layout[sector].address + sector_offset + chip->chunk_size - 1);
			fflush(stdout);
			if (!bytes_within_range(chip->layout[sector].address + sector_offset, 
			   chip->layout[sector].address + sector_offset + chip->chunk_size - 1)) {
				printf("not used\r\n");
				sector_offset += chip->chunk_size;
				if (sector_offset >= chip->layout[sector].size) {
					sector_offset = 0;
					sector++;
				}
				break;
			}
			snprintf(buf, sizeof(buf), "W %d %d\r\n", chip->ram_addr, chip->chunk_size);
			xmit_cmd(buf, 400);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "0\r\n") == 0) {
				state = XMIT_DATA;
				printf("xmit");
				current_addr = chip->layout[sector].address + sector_offset;
				num_to_xmit = chip->chunk_size;
				linecount = 0;
				cksum = 0;
				event = BEGIN;
				break;
			} else {
				download_cancel("can't xmit to ram"); 
				return;
			}
		  case TIMEOUT:
			download_cancel("No response"); 
			return;
		}
		break;


	  case XMIT_DATA:
		switch(event) {
		  case BEGIN:
			n = num_to_xmit;
			if (n > 45) n = 45;
			get_ihex_data(current_addr, n, bytes);
			cksum += sum(bytes, n);
			uuencode(buf, bytes, n);
			current_addr += n;
			num_to_xmit -= n;
			linecount++;
			xmit_cmd(buf, 500);
			write_serial_port("\r\n", 2);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "\r\n") == 0) {
				if (linecount >= 20 || num_to_xmit <= 0) {
					state = XMIT_CKSUM;
				}
				event = BEGIN;
				break;
			} else {
				download_cancel("data xmit did not echo"); 
				return;
			}
		  case TIMEOUT:
			download_cancel("No response"); 
			return;
		}
		break;


	  case XMIT_CKSUM:
		switch(event) {
		  case BEGIN:
			snprintf(buf, sizeof(buf), "%d\r\n", cksum);
			xmit_cmd(buf, 300);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "OK\r\n") == 0) {
				if (num_to_xmit > 0) {
					printf(".");
					fflush(stdout);
					state = XMIT_DATA;
					event = BEGIN;
					linecount = 0;
					cksum = 0;
					break;
				}
				state = WRITE_PREPARE;
				event = BEGIN;
				break;
			} else {
				download_cancel("bad checksum"); 
				return;
			}
		  case TIMEOUT:
			download_cancel("No response"); 
			return;
		}
		break;


	  case WRITE_PREPARE:
		switch(event) {
		  case BEGIN:
			printf("prep, ");
			fflush(stdout);
			snprintf(buf, sizeof(buf), "P %d %d\r\n", sector, sector);
			xmit_cmd(buf, 500);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "0\r\n") == 0) {
				state = WRITE_SECTOR;
				event = BEGIN;
				break;
			} else {
				download_cancel("Unable to prep for write"); 
				return;
			}
		  case TIMEOUT:
			download_cancel("No response"); 
			return;
		}
		break;


	  case WRITE_SECTOR:
		switch(event) {
		  case BEGIN:
			printf("write, ");
			fflush(stdout);
			snprintf(buf, sizeof(buf), "C %d %d %d\r\n",
				chip->layout[sector].address + sector_offset,
				chip->ram_addr, chip->chunk_size);
			xmit_cmd(buf, 500);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "0\r\n") == 0) {
				printf("Ok\r\n");
				sector_offset += chip->chunk_size;
				if (sector_offset >= chip->layout[sector].size) {
					sector_offset = 0;
					sector++;
				}
				state = DOWNLOAD_CODE;
				event = BEGIN;
			} else {
				download_cancel("Unable to prep for write"); 
				return;
			}
			break;
		  case TIMEOUT:
			download_cancel("No response"); 
			return;
		}
		break;


	  case BOOT_HARD:
		if (chip->bootprog) {
			state = BOOT_SOFT;
			break;
		} else {
			printf("Booting (hardware reset)...\r\n\r\n");
			hard_reset_to_user_code();
			state = IDLE;
			return;
		}

	  case BOOT_SOFT:
		switch(event) {
		  case BEGIN:
			printf("Booting (soft jump)...\r\n");
			printf("loading jump code\r\n");
			// would be nice if we could simply jump to the user's code, but
			// Philips didn't think of that.  The interrupt vector table stays
			// mapped to the bootloader, so jumping to zero only runs the
			// bootloader again.  Intead, we need to download a tiny ARM
			// program that reconfigures the hardware and then jumps to zero.
			//snprintf(buf, sizeof(buf), "G %d A\r\n", 0);
			snprintf(buf, sizeof(buf), "W %d %d\r\n", chip->ram_addr, chip->bootprog[0] * 4);
			xmit_cmd(buf, 400);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) < 1) return;
			if (strcmp(parsed_response_buf, "0\r\n") == 0) {
				current_addr = 0;
				num_to_xmit = chip->bootprog[0] * 4;
				copy_boot_code_to_memory(chip);
				linecount = 0;
				cksum = 0;
				state = BOOT_XMIT_DATA;
				event = BEGIN;
			} else {
				download_cancel("can't xmit to ram"); 
				return;
			}
			break;
		  case TIMEOUT:
			download_cancel("No response"); 
			return;
		}
		break;


	  case BOOT_XMIT_DATA:
		switch(event) {
		  case BEGIN:
			n = num_to_xmit;
			if (n > 45) n = 45;
			get_ihex_data(current_addr, n, bytes);
			cksum += sum(bytes, n);
			uuencode(buf, bytes, n);
			current_addr += n;
			num_to_xmit -= n;
			linecount++;
			//printf("send: %s\r\n", buf);
			xmit_cmd(buf, 500);
			write_serial_port("\r\n", 2);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "\r\n") == 0) {
				if (linecount >= 20 || num_to_xmit <= 0) {
					state = BOOT_XMIT_CKSUM;
				}
				event = BEGIN;
				break;
			} else {
				download_cancel("data xmit did not echo"); 
				return;
			}
		  case TIMEOUT:
			download_cancel("No response"); 
			return;
		}
		break;


	  case BOOT_XMIT_CKSUM:
		switch(event) {
		  case BEGIN:
			snprintf(buf, sizeof(buf), "%d\r\n", cksum);
			//printf("send: %s", buf);
			xmit_cmd(buf, 300);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) != 1) return;
			if (strcmp(parsed_response_buf, "OK\r\n") == 0) {
				if (num_to_xmit > 0) {
					printf(".");
					fflush(stdout);
					state = BOOT_XMIT_DATA;
					event = BEGIN;
					linecount = 0;
					cksum = 0;
					break;
				}
				state = BOOT_RUN_CODE;
				event = BEGIN;
				break;
			} else {
				download_cancel("bad checksum"); 
				return;
			}
		  case TIMEOUT:
			download_cancel("No response"); 
			return;
		}
		break;


	  case BOOT_RUN_CODE:
		switch(event) {
		  case BEGIN:
			printf("jumping now!\r\n");
			snprintf(buf, sizeof(buf), "G %d A\r\n", chip->ram_addr);
			xmit_cmd(buf, 400);
			return;
		  case RESPONSE:
			if (num_lines(parsed_response_buf) < 1) return;
			if (strcmp(parsed_response_buf, "0\r\n") == 0) {
				state = IDLE;
				return;
			} else {
				printf("response = %s", parsed_response_buf);
				download_cancel("couldn't run program"); 
				return;
			}
			break;
		  case TIMEOUT:
			state = IDLE;
			return;
			// Philips user name says it responds, but it does not.
			// It seems to just immediately jump to the code without
			// any "0" response.
			//download_cancel("No response"); return;
		}
		break;



	  default:
		  snprintf(buf, sizeof(buf), "unknown state %d\r\n", state);
		  download_cancel(buf);
		  return;
	}
    }
}


void download_cancel(const char *mesg)
{
	printf("\r\nDownload Canceled");
	if (mesg && *mesg) printf(": %s", mesg);
	printf("\r\n");
	// need to do some cleanup for various states???
	state = IDLE;
}


int download_in_progress(void)
{
	return (state != IDLE);
}


/****************************************************************/
/*								*/
/*		Transmit Commands to Bootloader			*/
/*								*/
/****************************************************************/



static void xmit_cmd(const char *cmd, int timeout_ms)
{
	int len;

	if (cmd == NULL || *cmd == '\0') return;
	len = strlen(cmd);

#ifdef PRINT_TX_RX_BYTES
	printf("tx %d bytes: %s\n", len, cmd);
#endif

	input_flush_serial_port();

	write_serial_port(cmd, len);

	snprintf(expected_echo_buf, sizeof(expected_echo_buf), "%s", cmd);
	if (state == SYNC_1) {
		// special case, baud sync doesn't echo
		expected_echo_buf[0] = '\0';
	}
	expected_echo_ptr = expected_echo_buf;
	parsed_response_ptr = parsed_response_buf;

	response_timeout = current_time_ms() + timeout_ms;
}



/****************************************************************/
/*								*/
/*		Handlers that respond to input			*/
/*								*/
/****************************************************************/


/*
Whenever the main gtk event loop detects more input has arrived from the
serial port, and we're in the process of a download, it calls here to
hand off the data.  We're supposed to match it up to the echo buffer,
and then store it into the parsed response buffer and if it looks like
this might be a complete response, call download_main with a response
event.
*/
void download_rx_port(const char *buf, int num)
{
	int i=0;

	if (num <= 0) return;

	// echo the data
	//write(term_fd, buf, num);

#ifdef PRINT_TX_RX_BYTES
	printf("rx %d bytes:", num);
	for (i=0; i<num; i++) {
		printf(" %02X", *(buf + i));
	}
	printf("\r\n");
#endif

	// ignore extra incoming garbage we didn't expect
	if (expected_echo_ptr == NULL) return;

	// special case, echo of '?' during unsuccessful sync
	if (state == SYNC_1 && num == 1 && buf[0] == '?') {
		*parsed_response_ptr++ = '?';
		*parsed_response_ptr = '\0';
		response_timeout = -1;
		download_main(RESPONSE);
		return;
	}

	// parse it
	for (i=0; i<num; i++) {
		// if we're still expecting the echo, gobble it up
		if (*expected_echo_ptr) {
			if (buf[i] != *expected_echo_ptr) {
#ifdef PRINT_TX_RX_BYTES
				printf("  <echo_err>  ");
#endif
				// ignore incorrect echo (will timeout)
				expected_echo_ptr = NULL;
				return;
			}
			expected_echo_ptr++;
			continue;
		}
		// store this into a parsed response buffer
		*parsed_response_ptr++ = buf[i];
	}

	// if the last two characters of the response are "\r\n",
	// then it's likely we've got a complete response.
	*parsed_response_ptr = '\0';
	if (parsed_response_ptr > parsed_response_buf + 1
	   && *(parsed_response_ptr - 2) == '\r'
	   && *(parsed_response_ptr - 1) == '\n') {
		download_main(RESPONSE);
	}
}



/*
During a download, this is supposed to get called at least at 100 Hz.  Whenever
something is transmitted and we expect a response, the response_timeout
is initialized to the deadline.
*/
void download_timer(void)
{
	if (response_timeout != -1) {
		if (response_timeout < current_time_ms()) {
			expected_echo_ptr = NULL;
			response_timeout = -1;
			download_main(TIMEOUT);
		}
	}
}


static long current_time_ms()
{
	static long last_t;
	long t;
	struct timeval tv;

	gettimeofday(&tv, NULL);
	t = 1000 * tv.tv_sec + tv.tv_usec / 1000;

	/* still works after midnight */
	if (t < last_t)
		t += 24 * 60 * 60 * 1000;

	last_t = t;
	return t;
}

