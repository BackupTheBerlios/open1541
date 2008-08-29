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
                .text "cmpay"
                .byte 0
test_start:
                jsr preconditions

                lda #0
                sta db
                sta ab
                sta yb

next:           lda db
                sta da
                sta dr

                lda ab
                sta ar
                sec
                sbc db
                php
                pla
                and #%10000011
                sta flags+1
                lda pb
                ora #%00110000
                and #%01111100
flags:          ora #0
                sta pr

                lda xb
                sta xr

                lda yb
                sta yr

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

cmd:            cmp da,y

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

                inc cmd+1
                bne noinc
                inc cmd+2
noinc:          lda yb
                bne nodec
                dec cmd+2
nodec:          dec yb

                clc
                lda db
                adc #17
                sta db
                bcc jmpnext
                lda #0
                sta db
                clc
                lda ab
                adc #17
                sta ab
                bcc jmpnext
                lda #0
                sta ab
                inc pb
                beq nonext
jmpnext:        jmp next
nonext:

                jmp end
.realpc
end:
.)
