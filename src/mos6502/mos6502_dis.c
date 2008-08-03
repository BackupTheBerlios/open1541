/*
    mos6502_dis - a 6502 disassembler

    (c) 2008 Thomas Giesel <skoe@directbox.com>
    Derived from 6502dis for use in mos6502 subsystem of open1541.
    Changes are mainly to disassemble from memory instead from a file
    and to replace fprintf by uart functions.

    Copyright (C) 2003 Written by Stian Soreng <skurk@multinet.no>
    http://freshmeat.net/projects/6502dis/

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <uart.h>
#include <stdint.h>
#include <mos6502.h>

static uint16_t  base;
static uint8_t   opcode;
static uint8_t   param1;
static uint8_t   param2;


static void two_bytes_opcode(char *cmd)
{
    param1 = mos6502_read_mem(base++);
    uart_puthex_padded(2, opcode);
    uart_putc(' ');
    uart_puthex_padded(2, param1);
    uart_putnc(12, ' ');
    uart_puts(cmd);
}

static void three_bytes_opcode(char *cmd)
{
    param1 = mos6502_read_mem(base++);
    param2 = mos6502_read_mem(base++);
    uart_puthex_padded(2, opcode);
    uart_putc(' ');
    uart_puthex_padded(2, param1);
    uart_putc(' ');
    uart_puthex_padded(2, param2);
    uart_putnc(9, ' ');
    uart_puts(cmd);
}

/* Print immediate
   example:   LDA #$5c
*/

static void immediate ( char *cmd )
{
    two_bytes_opcode(cmd);
    uart_puts(" #$");
    uart_puthex_padded(2, param1);
}

/* Print zero page
   example:   STA $9e
*/

static void zero_page ( char *cmd )
{
    two_bytes_opcode(cmd);
    uart_puts(" $");
    uart_puthex_padded(2, param1);
}

/* Print zero page with X
   example:   LDA $e1,X
*/

static void zero_page_x ( char *cmd )
{
    zero_page(cmd);
    uart_puts(",X");
}

/* Print zero page with Y
   example:   STA $11,Y
*/

static void zero_page_y ( char *cmd )
{
    zero_page(cmd);
    uart_puts(",Y");
}

/* Print absolute
   example:   LDA $4400
*/

static void absolute ( char *cmd )
{
    three_bytes_opcode(cmd);
    uart_puts(" $");
    uart_puthex_padded(4, (param2 << 8) | param1);
}

/* Print absolute with X
   example:   STA $5608,X
*/

static void absolute_x ( char *cmd )
{
    absolute(cmd);
    uart_puts(",X");
}

/* Print absolute with Y
   example:   STA $10a0,Y
*/

static void absolute_y ( char *cmd )
{
    absolute(cmd);
    uart_puts(",Y");
}

/* Print indirect with X
   example:   EOR ($5c,X)
*/

static void indirect_x ( char *cmd )
{
    two_bytes_opcode(cmd);
    uart_puts(" ($");
    uart_puthex_padded(2, param1);
    uart_puts(",X)");
}

/* Print indirect with Y
   example:   ROL ($9e),Y
*/

static void indirect_y ( char *cmd )
{
    two_bytes_opcode(cmd);
    uart_puts(" ($");
    uart_puthex_padded(2, param1);
    uart_puts("),Y");
}

/* Single opcodes
   example:   TAX
*/

static void single ( char *cmd )
{
    uart_puthex_padded(2, opcode);
    uart_putnc(15, ' ');
    uart_puts(cmd);
}

/* Branches
   example:   BNE $5c
*/

static void branch ( char *cmd )
{
    two_bytes_opcode(cmd);
    uart_puts(" $");

    if ( param1 < 0x80 )
    {
        uart_puthex_padded(4, base + param1);
    }
    else
    {
        uart_puthex_padded(4, base - (0x100 - param1) );
    }
}

/* Indirect absolute jumps
   example:   JMP ($5038)
*/

static void indir_jump()
{
    three_bytes_opcode("JMP");

    uart_puts(" ($");
    uart_puthex_padded(4, (param2 << 8) | param1);
    uart_putc(')');
}


/* Main ------------------------------------------------------------------ */

uint16_t mos6502_dis(uint16_t start, uint16_t stop)
{
    base = start;

    /* Start disassembling */

    while (base <= stop)
    {
        uart_putc('$');
        uart_puthex_padded(4, base);
        uart_putc(' ');

        opcode = mos6502_read_mem(base++);

        switch (opcode)
        {
            case 0x00:      single ( "BRK" ); break;
            case 0x01:  indirect_x ( "ORA" ); break;
            case 0x05:   zero_page ( "ORA" ); break;
            case 0x06:   zero_page ( "ASL" ); break;
            case 0x08:      single ( "PHP" ); break;
            case 0x09:   immediate ( "ORA" ); break;
            case 0x0a:      single ( "ASL" ); break;
            case 0x0d:    absolute ( "ORA" ); break;
            case 0x0e:    absolute ( "ASL" ); break;
            case 0x10:      branch ( "BPL" ); break;
            case 0x11:  indirect_y ( "ORA" ); break;
            case 0x15: zero_page_x ( "ORA" ); break;
            case 0x16: zero_page_x ( "ASL" ); break;
            case 0x18:      single ( "CLC" ); break;
            case 0x19:  indirect_y ( "ORA" ); break;
            case 0x1d:  absolute_x ( "ORA" ); break;
            case 0x1e:  absolute_x ( "ASL" ); break;
            case 0x20:    absolute ( "JSR" ); break;
            case 0x21:  indirect_x ( "AND" ); break;
            case 0x24:   zero_page ( "BIT" ); break;
            case 0x25:   zero_page ( "AND" ); break;
            case 0x26:   zero_page ( "ROL" ); break;
            case 0x28:      single ( "PLP" ); break;
            case 0x29:   immediate ( "AND" ); break;
            case 0x2a:      single ( "ROL" ); break;
            case 0x2c:    absolute ( "BIT" ); break;
            case 0x2d:    absolute ( "AND" ); break;
            case 0x2e:    absolute ( "ROL" ); break;
            case 0x30:      branch ( "BMI" ); break;
            case 0x31:  indirect_y ( "AND" ); break;
            case 0x35:  indirect_x ( "AND" ); break;
            case 0x36: zero_page_x ( "ROL" ); break;
            case 0x38:      single ( "SEC" ); break;
            case 0x39:  absolute_y ( "AND" ); break;
            case 0x3d:  absolute_x ( "AND" ); break;
            case 0x3e:  absolute_x ( "ROL" ); break;
            case 0x40:      single ( "RTI" ); break;
            case 0x41:  indirect_x ( "EOR" ); break;
            case 0x45:   zero_page ( "EOR" ); break;
            case 0x46:   zero_page ( "LSR" ); break;
            case 0x48:      single ( "PHA" ); break;
            case 0x49:   immediate ( "EOR" ); break;
            case 0x4a:      single ( "LSR" ); break;
            case 0x4c:    absolute ( "JMP" ); break;
            case 0x4d:    absolute ( "EOR" ); break;
            case 0x4e:    absolute ( "LSR" ); break;
            case 0x50:      branch ( "BVC" ); break;
            case 0x51:  indirect_y ( "EOR" ); break;
            case 0x55: zero_page_x ( "EOR" ); break;
            case 0x56: zero_page_x ( "LSR" ); break;
            case 0x58:      single ( "CLI" ); break;
            case 0x59:  absolute_y ( "EOR" ); break;
            case 0x5d:  absolute_x ( "EOR" ); break;
            case 0x5e:  absolute_x ( "LSR" ); break;
            case 0x60:      single ( "RTS" ); break;
            case 0x61:  indirect_x ( "ADC" ); break;
            case 0x65:   zero_page ( "ADC" ); break;
            case 0x66:   zero_page ( "ROR" ); break;
            case 0x68:      single ( "PLA" ); break;
            case 0x69:   immediate ( "ADC" ); break;
            case 0x6a:      single ( "ROR" ); break;
            case 0x6c:  indir_jump();         break;
            case 0x6d:    absolute ( "ADC" ); break;
            case 0x6e:    absolute ( "ROR" ); break;
            case 0x70:      branch ( "BVS" ); break;
            case 0x71:  indirect_y ( "ADC" ); break;
            case 0x75: zero_page_x ( "ADC" ); break;
            case 0x76: zero_page_x ( "ROR" ); break;
            case 0x78:      single ( "SEI" ); break;
            case 0x79:  absolute_y ( "ADC" ); break;
            case 0x7d:  absolute_x ( "ADC" ); break;
            case 0x7e:  absolute_x ( "ROR" ); break;
            case 0x81:  indirect_x ( "STA" ); break;
            case 0x84:   zero_page ( "STY" ); break;
            case 0x85:   zero_page ( "STA" ); break;
            case 0x86:   zero_page ( "STX" ); break;
            case 0x88:      single ( "DEY" ); break;
            case 0x8a:      single ( "TXA" ); break;
            case 0x8c:    absolute ( "STY" ); break;
            case 0x8d:    absolute ( "STA" ); break;
            case 0x8e:    absolute ( "STX" ); break;
            case 0x90:      branch ( "BCC" ); break;
            case 0x91:  indirect_y ( "STA" ); break;
            case 0x94: zero_page_x ( "STY" ); break;
            case 0x95: zero_page_x ( "STA" ); break;
            case 0x96: zero_page_y ( "STX" ); break;
            case 0x98:      single ( "TYA" ); break;
            case 0x99:  absolute_y ( "STA" ); break;
            case 0x9a:      single ( "TXS" ); break;
            case 0x9d:  absolute_x ( "STA" ); break;
            case 0xa0:   immediate ( "LDY" ); break;
            case 0xa1:  indirect_x ( "LDA" ); break;
            case 0xa2:   immediate ( "LDX" ); break;
            case 0xa4:   zero_page ( "LDY" ); break;
            case 0xa5:   zero_page ( "LDA" ); break;
            case 0xa6:   zero_page ( "LDX" ); break;
            case 0xa8:      single ( "TAY" ); break;
            case 0xa9:   immediate ( "LDA" ); break;
            case 0xaa:      single ( "TAX" ); break;
            case 0xac:    absolute ( "LDY" ); break;
            case 0xad:    absolute ( "LDA" ); break;
            case 0xae:    absolute ( "LDX" ); break;
            case 0xb0:      branch ( "BCS" ); break;
            case 0xb1:  indirect_y ( "LDA" ); break;
            case 0xb4: zero_page_x ( "LDY" ); break;
            case 0xb5: zero_page_x ( "LDA" ); break;
            case 0xb6: zero_page_y ( "LDX" ); break;
            case 0xb8:      single ( "CLV" ); break;
            case 0xb9:  absolute_y ( "LDA" ); break;
            case 0xba:      single ( "TSX" ); break;
            case 0xbc:  absolute_x ( "LDY" ); break;
            case 0xbd:  absolute_x ( "LDA" ); break;
            case 0xbe:  absolute_y ( "LDX" ); break;
            case 0xc0:   immediate ( "CPY" ); break;
            case 0xc1:  indirect_x ( "CMP" ); break;
            case 0xc4:   zero_page ( "CPY" ); break;
            case 0xc5:   zero_page ( "CMP" ); break;
            case 0xc6:   zero_page ( "DEC" ); break;
            case 0xc8:      single ( "INY" ); break;
            case 0xc9:   immediate ( "CMP" ); break;
            case 0xca:      single ( "DEX" ); break;
            case 0xcc:    absolute ( "CPY" ); break;
            case 0xcd:    absolute ( "CMP" ); break;
            case 0xce:    absolute ( "DEC" ); break;
            case 0xd0:      branch ( "BNE" ); break;
            case 0xd1:  indirect_y ( "CMP" ); break;
            case 0xd5: zero_page_x ( "CMP" ); break;
            case 0xd6: zero_page_x ( "DEC" ); break;
            case 0xd8:      single ( "CLD" ); break;
            case 0xd9:  absolute_y ( "CMP" ); break;
            case 0xdd:  absolute_x ( "CMP" ); break;
            case 0xde:  absolute_x ( "DEC" ); break;
            case 0xe0:   immediate ( "CPX" ); break;
            case 0xe1:  indirect_x ( "SBC" ); break;
            case 0xe4:   zero_page ( "CPX" ); break;
            case 0xe5:   zero_page ( "SBC" ); break;
            case 0xe6:   zero_page ( "INC" ); break;
            case 0xe8:      single ( "INX" ); break;
            case 0xe9:   immediate ( "SBC" ); break;
            case 0xea:      single ( "NOP" ); break;
            case 0xec:    absolute ( "CPX" ); break;
            case 0xed:    absolute ( "SBC" ); break;
            case 0xee:    absolute ( "INC" ); break;
            case 0xf0:      branch ( "BEQ" ); break;
            case 0xf1:  indirect_y ( "SBC" ); break;
            case 0xf5: zero_page_x ( "SBC" ); break;
            case 0xf6: zero_page_x ( "INC" ); break;
            case 0xf8:      single ( "SED" ); break;
            case 0xf9:  absolute_y ( "SBC" ); break;
            case 0xfd:  absolute_x ( "SBC" ); break;
            case 0xfe:  absolute_x ( "INC" ); break;
            default:
                uart_puthex_padded(2, opcode);
                uart_putnc(15, ' ');
                uart_puts(".BYTE $");
                uart_puthex_padded(2, opcode);
                break;
        }
        uart_putcrlf();
    }

    return base;
}

