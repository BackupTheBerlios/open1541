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
                .text "eora"
                .byte 0
test_start:
                jsr preconditions

                lda #0
                sta db
                sta ab

next:           lda db
                sta da
                sta dr
                sta cmd0+1
                eor #$ff
                sta cmd1+1

                lda ab
                eor #$ff
cmd0            and #0
                sta cmd2+1
                lda ab
cmd1            and #0
cmd2            ora #0
                sta ar

                lda xb
                sta xr

                lda yb
                sta yr

                lda pb
                ora #%00110000
                and #%01111101
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

cmd:            eor da

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
