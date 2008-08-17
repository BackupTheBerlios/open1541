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

    //memset(c1541_ram, 0xea, sizeof(c1541_ram));
    p = c1541_ram;

    *p++ = 0xa9;    // LDA #$81
    *p++ = 0x0f;

    *p++ = 0xa2;    // LDX #$01
    *p++ = 0x01;

    *p++ = 0x24;    // BIT $09
    *p++ = 0x09;

    *p++ = 0x4c;    // JMP $0000
    *p++ = 0x00;
    *p++ = 0x00;

    *p++ = 0xf0;
    mos6502_reset();
}
