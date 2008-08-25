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
                .text "tsxn"
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

                stx saves+1
                ldx #0
s0              lda $0100,x
                sta tmp_page,x
                inx
                bne s0

                lda #0
                sta sb

next:           lda db
                sta dr
                sta da

                lda ab
                sta ar

                lda yb
                sta yr

                lda pb
                ora #%00110000
                and #%01111101
                tax
                lda sb
                cmp #0
                bne nozero
                txa
                ora #%00000010
                tax
                lda sb
nozero:         asl
                bcc noneg
                txa
                ora #%10000000
                tax
noneg:          stx pr

                lda sb
                sta sr
                sta xr

                ldx sb
                txs
                lda pb
                pha
                lda ab
                ldx xb
                ldy yb
                plp

cmd:            tsx

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

                inc sb
jmpnext:        bne next
                inc pb
                bne jmpnext

saves:          ldx #0
                txs
                ldx #0
s1              lda tmp_page,x
                sta $0100,x
                inx
                bne s1

                jmp end
.realpc
end:
.)
