/*
 * lpc2134.ld - Linker script for LPC 2134
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

OUTPUT_ARCH(arm)
ENTRY(_begin)

MEMORY
{
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 128k
    RAM (rw) : ORIGIN = 0x40000000, LENGTH =  16k
}

STACK_SIZE = 1k;

SECTIONS
{
    .text :
    {
        *startup.o (.text)
        *(.text)
        *(.rodata)
    } > ROM

    . = ALIGN(4);
    _data_lma = . ;
    .data : AT (_data_lma)
    {
        _data_vma = .;
        *(.data)
        _end_data_vma = .;
    } > RAM

    . = ALIGN(4);
    .bss (NOLOAD) :
    {
        _bss_vma = . ;
        *(.bss)
        _end_bss_vma = . ;
    } > RAM

    .stack :
    {
        . = ALIGN(4);
        _stack_bottom = .;
        . += STACK_SIZE;
        _stack_top = .;
    } > RAM
}
