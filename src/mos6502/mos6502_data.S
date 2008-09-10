/*
    mos6502_data.S - definitions for data fields used by CPU emulation

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

/* This file must be included into mach_data.S */

@    size   symbol          offset to be defined
data    4   mos6502_sp      MOS6502_SP_OFFSET
data    4   mos6502_areg    MOS6502_A_OFFSET
data    4   mos6502_xreg    MOS6502_X_OFFSET
data    4   mos6502_yreg    MOS6502_Y_OFFSET

#if CONFIG_BREAKPOINTS > 0
breakpoint_space = CONFIG_BREAKPOINTS * 2
data breakpoint_space mos6502_bp MOS6502_BP_OFFSET
#endif
