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

    *p++ = 0x4c;    // JMP $0007 = code
    *p++ = 0x07;
    *p++ = 0x00;

    // pointers follow
// ptr0:
    *p++ = 0x00;
    *p++ = 0x00;
// ptr1:
    *p++ = 0x01;
    *p++ = 0x00;
// code:

    *p++ = 0xa0;    // LDY #$06
    *p++ = 0x06;

    *p++ = 0xb1;    // LDA ($05),Y
    *p++ = 0x05;    // must be = $a0

    *p++ = 0x29;    // AND #$20
    *p++ = 0x20;

    *p++ = 0xa9;    // LDA #$ea
    *p++ = 0xea;

    *p++ = 0x8d;    // STA $0007
    *p++ = 0x07;
    *p++ = 0x00;

    *p++ = 0xa2;    // LDX #$01
    *p++ = 0x01;

    *p++ = 0x95;    // STA $07,X
    *p++ = 0x07;

    *p++ = 0x4c;    // JMP $0000
    *p++ = 0x00;
    *p++ = 0x00;

    mos6502_reset();
}
