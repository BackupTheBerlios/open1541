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
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <sys/select.h>


#include "lpcflash.h"
#include "serial.h"
#include "settings.h"
#include "download.h"


static void do_port_input();


int main(int argc, char **argv)
{
	fd_set fds;
	struct timeval tv;
	int ret;

	if (init_settings(argc, argv) < 0)
		return 1;

	if (open_serial_port(port_setting()) < 0)
		return 1;

	//tg create_window(&argc, &argv);
	//tg run_gui();
        download_begin(); //tg

	while (download_in_progress()) {
		FD_ZERO(&fds);
		FD_SET(serial_port_fd(), &fds);
		tv.tv_sec  = 0;
		tv.tv_usec = 100 * 1000;
		ret = select(serial_port_fd() + 1, &fds, NULL, NULL, &tv);
		if (ret < 0) {
			fprintf(stderr, "Select: %s\n", strerror(errno));
			return 1;
		}
		else if (ret > 0) {
			do_port_input();
		}
		download_timer();
	}

	close_serial_port();
	return 0;
}


static void do_port_input()
{
	char buf[256];
	int num;

	num = read_serial_port_nb((unsigned char *)buf, sizeof(buf));
	if (num > 0) {
		download_rx_port(buf, num);
//		write(1, buf, num);
	}
}
