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

    *p++ = 0xa9;    // LDA #$00 = ret high
    *p++ = 0x00;

    *p++ = 0x48;    // PHA

    *p++ = 0xa9;    // LDA #$0C = ret low
    *p++ = 0x0C;

    *p++ = 0x48;    // PHA

    *p++ = 0xa9;    // LDA #$80 = flags
    *p++ = 0x80;

    *p++ = 0x48;    // PHA

    *p++ = 0x4c;    // JMP $000F (fake IRQ)
    *p++ = 0x0F;
    *p++ = 0x00;
// $000C:
    *p++ = 0x4c;    // JMP $0000
    *p++ = 0x00;
    *p++ = 0x00;
// $000F:
    *p++ = 0x40;    // RTI

    mos6502_reset();
}
