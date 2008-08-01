/*
 * arm7tdmi.h - Definitions for the ARM7TDMI processor
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

#ifndef ARM7TDMI_H
#define ARM7TDMI_H

/*
 * PSR bits
 */
#define MODE_USR    0x00000010
#define MODE_FIQ    0x00000011
#define MODE_IRQ    0x00000012
#define MODE_SVC    0x00000013
#define MODE_ABT    0x00000017
#define MODE_UND    0x0000001b
#define MODE_SYS    0x0000001f
#define MODE_MASK   0x0000001f
#define PSR_T       0x00000020
#define PSR_F       0x00000040
#define PSR_I       0x00000080
#define PSR_V       0x10000000
#define PSR_C       0x20000000
#define PSR_Z       0x40000000
#define PSR_N       0x80000000

#endif /* ARM7TDMI_H */
