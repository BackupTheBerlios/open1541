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
                .text "staiy"
                .byte 0
test_start:
                jsr preconditions

                lda #0
                sta ab
                sta yb
                lda #<da
                sta tmp_zp1
                lda #>da
                sta tmp_zp1+1

next:           lda db
                sta da

                lda ab
                sta ar
                sta dr

                lda xb
                sta xr

                lda yb
                sta yr

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

cmd:            sta (tmp_zp1),y

                php
                cld
                sta aa
                stx xa
                sty ya
                pla
                sta pa
                tsx
                stx sa
                jsr check

                inc tmp_zp1
                bne noinc
                inc tmp_zp1+1
noinc:          lda yb
                bne nodec
                dec tmp_zp1+1
nodec:          dec yb

                inc ab
jmpnext:        bne next
                inc pb
                bne jmpnext

                jmp end
.realpc
end:
.)
