/*
 * mos6502 - a 6502 emulator
 *
 * (c) 2008, 2009 Thomas Giesel
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 *
 * Thomas Giesel skoe@directbox.com
 */

/* This file must be included into mach_data.S */

@    size   symbol              offset to be defined
data    4   mos6502_sp          MOS6502_SP_OFFSET
data    4   mos6502_areg        MOS6502_A_OFFSET
data    4   mos6502_xreg        MOS6502_X_OFFSET
data    4   mos6502_yreg        MOS6502_Y_OFFSET
data    4   mos6503_pc_offset   MOS6502_PC_OFFSET_OFFSET

#if CONFIG_BREAKPOINTS > 0
breakpoint_space = CONFIG_BREAKPOINTS * 2
data breakpoint_space mos6502_bp MOS6502_BP_OFFSET
#endif
