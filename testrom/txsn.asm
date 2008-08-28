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
                .text "txsn"
                .byte 0
test_start:
                jsr preconditions

                stx saves+1
                ldx #0
s0              lda $0100,x
                sta tmp_page,x
                inx
                bne s0

                lda #0
                sta xb

next:           lda db
                sta dr
                sta da

                lda ab
                sta ar

                lda xb
                sta xr
                sta sr

                lda yb
                sta yr

                lda pb
                ora #%00110000
                sta pr

                ldx sb
                txs
                lda pb
                pha
                lda ab
                ldx xb
                ldy yb
                plp

cmd:            txs

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

                inc xb
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
