/*
 * open1541.c - The main program
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

#include <stdint.h>
#include <string.h>
#include <mos6502.h>

uint8_t c1541_ram[2048];

/*******************************************************************************
 * Initialize the C1541 emulation.
 *
 ******************************************************************************/
void c1541_init(void)
{
    uint8_t* p;

    p = c1541_ram;

    *p++ = 0xa2;    // LDX #$10
    *p++ = 0x10;

    *p++ = 0xe0;    // CPX #$10 => ZC
    *p++ = 0x10;

    *p++ = 0xe0;    // CPX #$05 => C
    *p++ = 0x05;

    *p++ = 0xe0;    // CPX #$20 => N
    *p++ = 0x20;

    *p++ = 0xe0;    // CPX #$E0 => -
    *p++ = 0xe0;

    *p++ = 0xa2;    // LDX #$F0
    *p++ = 0xf0;

    *p++ = 0xe0;    // CPX #$F0 => ZC
    *p++ = 0xf0;

    *p++ = 0xe0;    // CPX #$10 => NC
    *p++ = 0x10;

    *p++ = 0xe0;    // CPX #$E0 => C
    *p++ = 0xe0;

    *p++ = 0xe0;    // CPX #$FF => N
    *p++ = 0xff;

    *p++ = 0x4c;    // JMP $0000
    *p++ = 0x00;
    *p++ = 0x00;

    mos6502_reset();
    mos6502_run();
}
