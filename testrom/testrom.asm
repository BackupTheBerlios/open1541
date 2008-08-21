/*
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
 *
 */

tmp_zp1     = $2c
tmp_zp2     = $3b
tmp_page    = $0700

; Temporary storage for test cases
tmp_storage = $0400
db          = tmp_storage +  0
ab          = tmp_storage +  1
xb          = tmp_storage +  2
yb          = tmp_storage +  3
pb          = tmp_storage +  4
sb          = tmp_storage +  5
da          = tmp_storage +  6
aa          = tmp_storage +  7
xa          = tmp_storage +  8
ya          = tmp_storage +  9
pa          = tmp_storage + 10
sa          = tmp_storage + 11
dr          = tmp_storage + 12
ar          = tmp_storage + 13
xr          = tmp_storage + 14
yr          = tmp_storage + 15
pr          = tmp_storage + 16
sr          = tmp_storage + 17

; Self-modifying code may run there
ram_code    = $0500

* = $c000
start:

; test cases
;#include <ldaa.asm>
#include <ldaax.asm>



        ldx #$10    ; => -

        cpx #$10    ; => ZC
        cpx #$05    ; => C
        cpx #$20    ; => N
        cpx #$E0    ; => -

        ldx #$F0    ; => N

        cpx #$F0    ; => ZC
        cpx #$10    ; => NC
        cpx #$e0    ; => C
        cpx #$ff    ; => N

        jmp start


error_end:
        jmp error_end

;===============================================================================
; Fill (16k - code size - vector size) with $ff
        .dsb $4000 - (* - start) - 6, $ff
;===============================================================================
; Vectors
        ; NMI vector
        .word start
        ; Reset vector
        .word start
        ; IRQ vector
        .word start
;===============================================================================
