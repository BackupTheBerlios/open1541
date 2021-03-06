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
                .text "rolax"
                .byte 0
test_start:
                jsr preconditions

                lda #0
                sta db
                sta xb

next:           lda db
                sta da
                asl
                sta dr
                lda pb
                and #1
                ora dr
                sta dr

                lda ab
                sta ar

                lda xb
                sta xr

                lda yb
                sta yr

                lda pb
                ora #%00110000
                and #%01111100
                tax
                lda dr
                cmp #0
                bne nozero
                txa
                ora #%00000010
                tax
nozero:         lda dr
                bpl noneg
                txa
                ora #%10000000
                tax
noneg:          lda db
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

cmd:            rol da,x

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
noinc:          lda xb
                bne nodec
                dec cmd+2
nodec:          dec xb

                inc db
                bne jmpnext
                inc pb
                beq nonext
jmpnext:        jmp next
nonext:

                jmp end
.realpc
end:
.)
