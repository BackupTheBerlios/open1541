; This test case is based on C64 Emulator Test Suite
; by Wolfgang Lorenz and Christer Palm
; Public Domain, no Copyright

.(
                ; copy testcode to RAM
                ldx #0
copy_code:
                lda copy_this, x
                sta ram_code, x
                dex
                bne copy_code
                jmp ram_code + test_start - test_name
copy_this:
.pseudopc ram_code
test_name:
                .text "styzx"
                .byte 0
test_start:
                jsr preconditions

                lda #0
                sta yb
                sta xb

next:           lda db
                sta tmp_zp1

                lda ab
                sta ar

                lda xb
                sta xr

                lda yb
                sta yr
                sta dr

                lda pb
                ora #%00110000
                sta pr

                lda sb
                sta sr

                ldx sb
                txs
                lda pb
                pha
                lda ab
                ldx xb
                ldy yb
                plp

cmd:            sty tmp_zp1,x

                php
                cld
                sta aa
                stx xa
                sty ya
                pla
                sta pa
                tsx
                stx sa
                lda tmp_zp1
                sta da
                jsr check

                inc cmd+1
                dec xb

                inc yb
jmpnext:        bne next
                inc pb
                bne jmpnext

                jmp end
.realpc
end:
.)
