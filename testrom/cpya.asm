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
                .text "cpya"
                .byte 0
test_start:
                lda #%00011011
                sta db
                lda #%11000110
                sta ab
                lda #%10110001
                sta xb
                lda #%01101100
                sta yb
                lda #0
                sta pb
                tsx
                stx sb

                lda #0
                sta db
                sta yb

next:           lda db
                sta da
                sta dr

                lda yb
                sta yr
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

                lda ab
                sta ar

                lda xb
                sta xr

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

cmd:            cpy da

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
                lda yb
                adc #17
                sta yb
                bcc jmpnext
                lda #0
                sta yb
                inc pb
                beq nonext
jmpnext:        jmp next
nonext:

                jmp end
.realpc
end:
.)
