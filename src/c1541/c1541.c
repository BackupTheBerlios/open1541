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
    *p++ = 0xea;    // NOP

    *p++ = 0xa5;    // LDA $01 (= $a5)
    *p++ = 0x01;

    *p++ = 0xa2;    // LDX #$fe
    *p++ = 0xfe;

// there:
    *p++ = 0xe8;    // INX

    *p++ = 0xd0;    // BNE there
    *p++ = (uint8_t)(-3);

    *p++ = 0x18;    // CLC
    *p++ = 0x69;    // ADC #1
    *p++ = 0x01;

    *p++ = 0x38;    // SEC
    *p++ = 0x69;    // ADC #$80
    *p++ = 0x80;

    *p++ = 0x69;    // ADC #$80
    *p++ = 0x80;

    *p++ = 0x4c;    // JMP $0000
    *p++ = 0x00;
    *p++ = 0x00;

    mos6502_reset();
}
