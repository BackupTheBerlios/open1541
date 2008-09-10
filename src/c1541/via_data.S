/*
    via_data.S - definitions for data fields used by VIA emulation

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

#include <via.h>

@    size           symbol              offset to be defined
data VIA_REG_SIZE   via1_reg_mirror     VIA1_REGS_OFFSET
data VIA_REG_SIZE   via2_reg_mirror     VIA2_REGS_OFFSET

data 4              via1_t1_exp         VIA1_T1_EXP_OFFSET
data 4              via1_t2_exp         VIA1_T2_EXP_OFFSET
data 4              via2_t1_exp         VIA2_T1_EXP_OFFSET
data 4              via2_t2_exp         VIA2_T2_EXP_OFFSET
