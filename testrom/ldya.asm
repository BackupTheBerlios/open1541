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
                .text "ldya"
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

next:           lda db
                sta da
                sta dr
                sta yr

                lda ab
                sta ar

                lda xb
                sta xr

                lda pb
                ora #%00110000
                and #%01111101
                tax
                lda dr
                cmp #0
                bne nozero
                txa
                ora #%00000010
                tax
                lda dr
nozero:         asl
                bcc noneg
                txa
                ora #%10000000
                tax
noneg:          stx pr

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

cmd:            ldy da

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

                inc db
jmpnext:        bne next
                inc pb
                bne jmpnext

                jmp end
.realpc
end:
.)
