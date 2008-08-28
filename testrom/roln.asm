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
                .text "roln"
                .byte 0
test_start:
                jsr preconditions

                lda #0
                sta ab

next:           lda db
                sta da
                sta dr

                lda ab
                asl
                sta ar
                lda pb
                and #1
                ora ar
                sta ar

                lda xb
                sta xr

                lda yb
                sta yr

                lda pb
                ora #%00110000
                and #%01111100
                tax
                lda ar
                cmp #0
                bne nozero
                txa
                ora #%00000010
                tax
nozero:         lda ar
                bpl noneg
                txa
                ora #%10000000
                tax
noneg:          lda ab
                and #128
                beq no_carry
                txa
                ora #%00000001
                tax
no_carry         stx pr

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

cmd:            rol

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

                inc ab
                bne jmpnext
                inc pb
                beq nonext
jmpnext:        jmp next
nonext:

                jmp end
.realpc
end:
.)
