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
                .text "bita"
                .byte 0
test_start:
                jsr preconditions

                lda #0
                sta db
                sta ab

next:           lda db
                sta da
                sta dr

                lda ab
                sta ar

                lda xb
                sta xr

                lda yb
                sta yr

                lda pb
                ora #%00110000
                and #%00111101
                tax
                lda ab
                and db
                bne nozero
                txa
                ora #%00000010
                tax
nozero:         lda db
                and #%11000000
                sta l0+1
                txa
l0              ora #0
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

cmd:            bit da

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
