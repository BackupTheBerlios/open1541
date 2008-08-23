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

; this counter starts at 0 and is incremented after completing all tests 
; successfully
test_loop_counter = $02

; two bytes in zero page
tmp_zp1     = $2c

; two bytes in zero page
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
            lda #0
            sta test_loop_counter
test_again:

; test cases
#include "ldaa.asm"
#include "ldaax.asm"
#include "ldaay.asm"
#include "ldaix.asm"
#include "ldaiy.asm"
#include "ldaz.asm"
#include "ldazx.asm"
#include "staa.asm"
#include "staax.asm"
#include "staay.asm"
#include "staix.asm"
#include "staiy.asm"
#include "staz.asm"
#include "stazx.asm"
#include "ldxa.asm"
#include "ldxay.asm"
#include "ldxb.asm"
#include "ldxz.asm"
#include "ldxzy.asm"
#include "stxa.asm"
#include "stxz.asm"
#include "stxzy.asm"
#include "ldya.asm"
#include "ldyax.asm"
#include "ldyb.asm"
#include "ldyz.asm"
#include "ldyzx.asm"
#include "stya.asm"
#include "styz.asm"
#include "styzx.asm"
#include "dexn.asm"
#include "inxn.asm"
#include "deyn.asm"
#include "inyn.asm"
#include "deca.asm"
#include "decax.asm"
#include "decz.asm"
#include "deczx.asm"
#include "inca.asm"
#include "incax.asm"
#include "incz.asm"
#include "inczx.asm"

            inc test_loop_counter
            jmp test_again

check:
            lda da
            cmp dr
            bne error
            lda aa
            cmp ar
            bne error
            lda xa
            cmp xr
            bne error
            lda ya
            cmp yr
            bne error
            lda pa
            cmp pr
            bne error
            lda sa
            cmp sr
            bne error
            rts
error:
            jmp error

;===============================================================================
; Fill (16k - code size - vector size) with $ff
;        .dsb $4000 - (* - start) - 6, $ff
;===============================================================================
; Vectors
* = $fffa
            ; NMI vector
            .word start
            ; Reset vector
            .word start
            ; IRQ vector
            .word start
;===============================================================================
