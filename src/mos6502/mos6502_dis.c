/*
 * mos6502_dis - a 6502 disassembler
 *
 * (c) 2008 Thomas Giesel
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 *
 * Thomas Giesel skoe@directbox.com
 */

#include <uart.h>
#include <stdint.h>

#include "mos6502.h"

static void single_byte_opcode(void);
static void two_bytes_opcode(void);
static void three_bytes_opcode(void);
static void addr_mode_undef(void);
static void addr_mode_acc(void);
static void addr_mode_imp(void);
static void addr_mode_imm(void);
static void addr_mode_zp(void);
static void addr_mode_zpx(void);
static void addr_mode_zpy(void);
static void addr_mode_abs(void);
static void addr_mode_absx(void);
static void addr_mode_absy(void);
static void addr_mode_absi(void);
static void addr_mode_indx(void);
static void addr_mode_indy(void);
static void addr_mode_rel(void);


/* Addressing modes, used as table index */
#define ADDR_MODE_UNDEF     0
#define ADDR_MODE_ACC       1
#define ADDR_MODE_IMP       2
#define ADDR_MODE_IMM       3
#define ADDR_MODE_ZP        4
#define ADDR_MODE_ZPX       5
#define ADDR_MODE_ZPY       6
#define ADDR_MODE_ABS       7
#define ADDR_MODE_ABSX      8
#define ADDR_MODE_ABSY      9
#define ADDR_MODE_ABSI     10
#define ADDR_MODE_INDX     11
#define ADDR_MODE_INDY     12
#define ADDR_MODE_REL      13

/* Number of bytes for each addressing mode */
static const uint8_t addr_mode_length[] =
{
    1,  /* ADDR_MODE_UNDEF */
    1,  /* ADDR_MODE_ACC */
    1,  /* ADDR_MODE_IMP */
    2,  /* ADDR_MODE_IMM */
    2,  /* ADDR_MODE_ZP */
    2,  /* ADDR_MODE_ZPX */
    2,  /* ADDR_MODE_ZPY */
    3,  /* ADDR_MODE_ABS */
    3,  /* ADDR_MODE_ABSX */
    3,  /* ADDR_MODE_ABSY */
    3,  /* ADDR_MODE_ABSI */
    2,  /* ADDR_MODE_INDX */
    2,  /* ADDR_MODE_INDY */
    2   /* ADDR_MODE_REL */
};

/* Function pointer for each addressing mode */
typedef void (*addr_mode_fn_t)(void);
static const addr_mode_fn_t addr_mode_fn[] =
{
    addr_mode_undef,
    addr_mode_acc,
    addr_mode_imp,
    addr_mode_imm,
    addr_mode_zp,
    addr_mode_zpx,
    addr_mode_zpy,
    addr_mode_abs,
    addr_mode_absx,
    addr_mode_absy,
    addr_mode_absi,
    addr_mode_indx,
    addr_mode_indy,
    addr_mode_rel,
};

/* Mnemonics, used as table index */
#define MNEMONIC_ADC    0
#define MNEMONIC_AND    1
#define MNEMONIC_ASL    2
#define MNEMONIC_BCC    3
#define MNEMONIC_BCS    4
#define MNEMONIC_BEQ    5
#define MNEMONIC_BIT    6
#define MNEMONIC_BMI    7
#define MNEMONIC_BNE    8
#define MNEMONIC_BPL    9
#define MNEMONIC_BRK   10
#define MNEMONIC_BVC   11
#define MNEMONIC_BVS   12
#define MNEMONIC_CLC   13
#define MNEMONIC_CLD   14
#define MNEMONIC_CLI   15
#define MNEMONIC_CLV   16
#define MNEMONIC_CMP   17
#define MNEMONIC_CPX   18
#define MNEMONIC_CPY   19
#define MNEMONIC_DEC   20
#define MNEMONIC_DEX   21
#define MNEMONIC_DEY   22
#define MNEMONIC_EOR   23
#define MNEMONIC_INC   24
#define MNEMONIC_INX   25
#define MNEMONIC_INY   26
#define MNEMONIC_JMP   27
#define MNEMONIC_JSR   28
#define MNEMONIC_LDA   29
#define MNEMONIC_LDX   30
#define MNEMONIC_LDY   31
#define MNEMONIC_LSR   32
#define MNEMONIC_NOP   33
#define MNEMONIC_ORA   34
#define MNEMONIC_PHA   35
#define MNEMONIC_PHP   36
#define MNEMONIC_PLA   37
#define MNEMONIC_PLP   38
#define MNEMONIC_ROL   39
#define MNEMONIC_ROR   40
#define MNEMONIC_RTI   41
#define MNEMONIC_RTS   42
#define MNEMONIC_SBC   43
#define MNEMONIC_SEC   44
#define MNEMONIC_SED   45
#define MNEMONIC_SEI   46
#define MNEMONIC_STA   47
#define MNEMONIC_STX   48
#define MNEMONIC_STY   49
#define MNEMONIC_TAX   50
#define MNEMONIC_TAY   51
#define MNEMONIC_TSX   52
#define MNEMONIC_TXA   53
#define MNEMONIC_TXS   54
#define MNEMONIC_TYA   55
#define MNEMONIC_XXX   56
#define MNEMONIC_COUNT 57

/* This is a table of all mnemonics' texts */
static const char* mnemonics[MNEMONIC_COUNT] =
{
    "ADC", "AND", "ASL", "BCC", "BCS", "BEQ", "BIT", "BMI", "BNE", "BPL",
    "BRK", "BVC", "BVS", "CLC", "CLD", "CLI", "CLV", "CMP", "CPX", "CPY",
    "DEC", "DEX", "DEY", "EOR", "INC", "INX", "INY", "JMP", "JSR", "LDA",
    "LDX", "LDY", "LSR", "NOP", "ORA", "PHA", "PHP", "PLA", "PLP", "ROL",
    "ROR", "RTI", "RTS", "SBC", "SEC", "SED", "SEI", "STA", "STX", "STY",
    "TAX", "TAY", "TSX", "TXA", "TXS", "TYA", "???"
};


typedef struct mos6502_instruction_s
{
    uint8_t mnemonic_idx;
    uint8_t addr_mode_idx;
}
mos6502_instruction_t;

static const mos6502_instruction_t inst_map[256] =
{
    { MNEMONIC_BRK, ADDR_MODE_IMP    }, /* 00 */
    { MNEMONIC_ORA, ADDR_MODE_INDX   }, /* 01 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 02 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 03 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 04 */
    { MNEMONIC_ORA, ADDR_MODE_ZP     }, /* 05 */
    { MNEMONIC_ASL, ADDR_MODE_ZP     }, /* 06 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 07 */
    { MNEMONIC_PHP, ADDR_MODE_IMP    }, /* 08 */
    { MNEMONIC_ORA, ADDR_MODE_IMM    }, /* 09 */
    { MNEMONIC_ASL, ADDR_MODE_ACC    }, /* 0a */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 0b */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 0c */
    { MNEMONIC_ORA, ADDR_MODE_ABS    }, /* 0d */
    { MNEMONIC_ASL, ADDR_MODE_ABS    }, /* 0e */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 0f */
    { MNEMONIC_BPL, ADDR_MODE_REL    }, /* 10 */
    { MNEMONIC_ORA, ADDR_MODE_INDY   }, /* 11 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 12 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 13 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 14 */
    { MNEMONIC_ORA, ADDR_MODE_ZPX    }, /* 15 */
    { MNEMONIC_ASL, ADDR_MODE_ZPX    }, /* 16 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 17 */
    { MNEMONIC_CLC, ADDR_MODE_IMP    }, /* 18 */
    { MNEMONIC_ORA, ADDR_MODE_ABSY   }, /* 19 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 1a */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 1b */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 1c */
    { MNEMONIC_ORA, ADDR_MODE_ABSX   }, /* 1d */
    { MNEMONIC_ASL, ADDR_MODE_ABSX   }, /* 1e */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 1f */
    { MNEMONIC_JSR, ADDR_MODE_ABS    }, /* 20 */
    { MNEMONIC_AND, ADDR_MODE_INDX   }, /* 21 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 22 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 23 */
    { MNEMONIC_BIT, ADDR_MODE_ZP     }, /* 24 */
    { MNEMONIC_AND, ADDR_MODE_ZP     }, /* 25 */
    { MNEMONIC_ROL, ADDR_MODE_ZP     }, /* 26 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 27 */
    { MNEMONIC_PLP, ADDR_MODE_IMP    }, /* 28 */
    { MNEMONIC_AND, ADDR_MODE_IMM    }, /* 29 */
    { MNEMONIC_ROL, ADDR_MODE_ACC    }, /* 2a */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 2b */
    { MNEMONIC_BIT, ADDR_MODE_ABS    }, /* 2c */
    { MNEMONIC_AND, ADDR_MODE_ABS    }, /* 2d */
    { MNEMONIC_ROL, ADDR_MODE_ABS    }, /* 2e */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 2f */
    { MNEMONIC_BMI, ADDR_MODE_REL    }, /* 30 */
    { MNEMONIC_AND, ADDR_MODE_INDY   }, /* 31 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 32 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 33 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 34 */
    { MNEMONIC_AND, ADDR_MODE_ZPX    }, /* 35 */
    { MNEMONIC_ROL, ADDR_MODE_ZPX    }, /* 36 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 37 */
    { MNEMONIC_SEC, ADDR_MODE_IMP    }, /* 38 */
    { MNEMONIC_AND, ADDR_MODE_ABSY   }, /* 39 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 3a */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 3b */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 3c */
    { MNEMONIC_AND, ADDR_MODE_ABSX   }, /* 3d */
    { MNEMONIC_ROL, ADDR_MODE_ABSX   }, /* 3e */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 3f */
    { MNEMONIC_RTI, ADDR_MODE_IMP    }, /* 40 */
    { MNEMONIC_EOR, ADDR_MODE_INDX   }, /* 41 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 42 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 43 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 44 */
    { MNEMONIC_EOR, ADDR_MODE_ZP     }, /* 45 */
    { MNEMONIC_LSR, ADDR_MODE_ZP     }, /* 46 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 47 */
    { MNEMONIC_PHA, ADDR_MODE_IMP    }, /* 48 */
    { MNEMONIC_EOR, ADDR_MODE_IMM    }, /* 49 */
    { MNEMONIC_LSR, ADDR_MODE_ACC    }, /* 4a */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 4b */
    { MNEMONIC_JMP, ADDR_MODE_ABS    }, /* 4c */
    { MNEMONIC_EOR, ADDR_MODE_ABS    }, /* 4d */
    { MNEMONIC_LSR, ADDR_MODE_ABS    }, /* 4e */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 4f */
    { MNEMONIC_BVC, ADDR_MODE_REL    }, /* 50 */
    { MNEMONIC_EOR, ADDR_MODE_INDY   }, /* 51 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 52 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 53 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 54 */
    { MNEMONIC_EOR, ADDR_MODE_ZPX    }, /* 55 */
    { MNEMONIC_LSR, ADDR_MODE_ZPX    }, /* 56 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 57 */
    { MNEMONIC_CLI, ADDR_MODE_IMP    }, /* 58 */
    { MNEMONIC_EOR, ADDR_MODE_ABSY   }, /* 59 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 5a */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 5b */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 5c */
    { MNEMONIC_EOR, ADDR_MODE_ABSX   }, /* 5d */
    { MNEMONIC_LSR, ADDR_MODE_ABSX   }, /* 5e */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 5f */
    { MNEMONIC_RTS, ADDR_MODE_IMP    }, /* 60 */
    { MNEMONIC_ADC, ADDR_MODE_INDX   }, /* 61 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 62 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 63 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 64 */
    { MNEMONIC_ADC, ADDR_MODE_ZP     }, /* 65 */
    { MNEMONIC_ROR, ADDR_MODE_ZP     }, /* 66 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 67 */
    { MNEMONIC_PLA, ADDR_MODE_IMP    }, /* 68 */
    { MNEMONIC_ADC, ADDR_MODE_IMM    }, /* 69 */
    { MNEMONIC_ROR, ADDR_MODE_ACC    }, /* 6a */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 6b */
    { MNEMONIC_JMP, ADDR_MODE_ABSI   }, /* 6c */
    { MNEMONIC_ADC, ADDR_MODE_ABS    }, /* 6d */
    { MNEMONIC_ROR, ADDR_MODE_ABS    }, /* 6e */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 6f */
    { MNEMONIC_BVS, ADDR_MODE_REL    }, /* 70 */
    { MNEMONIC_ADC, ADDR_MODE_INDY   }, /* 71 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 72 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 73 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 74 */
    { MNEMONIC_ADC, ADDR_MODE_ZPX    }, /* 75 */
    { MNEMONIC_ROR, ADDR_MODE_ZPX    }, /* 76 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 77 */
    { MNEMONIC_SEI, ADDR_MODE_IMP    }, /* 78 */
    { MNEMONIC_ADC, ADDR_MODE_ABSY   }, /* 79 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 7a */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 7b */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 7c */
    { MNEMONIC_ADC, ADDR_MODE_ABSX   }, /* 7d */
    { MNEMONIC_ROR, ADDR_MODE_ABSX   }, /* 7e */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 7f */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 80 */
    { MNEMONIC_STA, ADDR_MODE_INDX   }, /* 81 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 82 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 83 */
    { MNEMONIC_STY, ADDR_MODE_ZP     }, /* 84 */
    { MNEMONIC_STA, ADDR_MODE_ZP     }, /* 85 */
    { MNEMONIC_STX, ADDR_MODE_ZP     }, /* 86 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 87 */
    { MNEMONIC_DEY, ADDR_MODE_IMP    }, /* 88 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 89 */
    { MNEMONIC_TXA, ADDR_MODE_IMP    }, /* 8a */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 8b */
    { MNEMONIC_STY, ADDR_MODE_ABS    }, /* 8c */
    { MNEMONIC_STA, ADDR_MODE_ABS    }, /* 8d */
    { MNEMONIC_STX, ADDR_MODE_ABS    }, /* 8e */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 8f */
    { MNEMONIC_BCC, ADDR_MODE_REL    }, /* 90 */
    { MNEMONIC_STA, ADDR_MODE_INDY   }, /* 91 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 92 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 93 */
    { MNEMONIC_STY, ADDR_MODE_ZPX    }, /* 94 */
    { MNEMONIC_STA, ADDR_MODE_ZPX    }, /* 95 */
    { MNEMONIC_STX, ADDR_MODE_ZPY    }, /* 96 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 97 */
    { MNEMONIC_TYA, ADDR_MODE_IMP    }, /* 98 */
    { MNEMONIC_STA, ADDR_MODE_ABSY   }, /* 99 */
    { MNEMONIC_TXS, ADDR_MODE_IMP    }, /* 9a */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 9b */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 9c */
    { MNEMONIC_STA, ADDR_MODE_ABSX   }, /* 9d */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 9e */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* 9f */
    { MNEMONIC_LDY, ADDR_MODE_IMM    }, /* a0 */
    { MNEMONIC_LDA, ADDR_MODE_INDX   }, /* a1 */
    { MNEMONIC_LDX, ADDR_MODE_IMM    }, /* a2 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* a3 */
    { MNEMONIC_LDY, ADDR_MODE_ZP     }, /* a4 */
    { MNEMONIC_LDA, ADDR_MODE_ZP     }, /* a5 */
    { MNEMONIC_LDX, ADDR_MODE_ZP     }, /* a6 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* a7 */
    { MNEMONIC_TAY, ADDR_MODE_IMP    }, /* a8 */
    { MNEMONIC_LDA, ADDR_MODE_IMM    }, /* a9 */
    { MNEMONIC_TAX, ADDR_MODE_IMP    }, /* aa */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* ab */
    { MNEMONIC_LDY, ADDR_MODE_ABS    }, /* ac */
    { MNEMONIC_LDA, ADDR_MODE_ABS    }, /* ad */
    { MNEMONIC_LDX, ADDR_MODE_ABS    }, /* ae */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* af */
    { MNEMONIC_BCS, ADDR_MODE_REL    }, /* b0 */
    { MNEMONIC_LDA, ADDR_MODE_INDY   }, /* b1 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* b2 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* b3 */
    { MNEMONIC_LDY, ADDR_MODE_ZPX    }, /* b4 */
    { MNEMONIC_LDA, ADDR_MODE_ZPX    }, /* b5 */
    { MNEMONIC_LDX, ADDR_MODE_ZPY    }, /* b6 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* b7 */
    { MNEMONIC_CLV, ADDR_MODE_IMP    }, /* b8 */
    { MNEMONIC_LDA, ADDR_MODE_ABSY   }, /* b9 */
    { MNEMONIC_TSX, ADDR_MODE_IMP    }, /* ba */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* bb */
    { MNEMONIC_LDY, ADDR_MODE_ABSX   }, /* bc */
    { MNEMONIC_LDA, ADDR_MODE_ABSX   }, /* bd */
    { MNEMONIC_LDX, ADDR_MODE_ABSY   }, /* be */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* bf */
    { MNEMONIC_CPY, ADDR_MODE_IMM    }, /* c0 */
    { MNEMONIC_CMP, ADDR_MODE_INDX   }, /* c1 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* c2 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* c3 */
    { MNEMONIC_CPY, ADDR_MODE_ZP     }, /* c4 */
    { MNEMONIC_CMP, ADDR_MODE_ZP     }, /* c5 */
    { MNEMONIC_DEC, ADDR_MODE_ZP     }, /* c6 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* c7 */
    { MNEMONIC_INY, ADDR_MODE_IMP    }, /* c8 */
    { MNEMONIC_CMP, ADDR_MODE_IMM    }, /* c9 */
    { MNEMONIC_DEX, ADDR_MODE_IMP    }, /* ca */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* cb */
    { MNEMONIC_CPY, ADDR_MODE_ABS    }, /* cc */
    { MNEMONIC_CMP, ADDR_MODE_ABS    }, /* cd */
    { MNEMONIC_DEC, ADDR_MODE_ABS    }, /* ce */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* cf */
    { MNEMONIC_BNE, ADDR_MODE_REL    }, /* d0 */
    { MNEMONIC_CMP, ADDR_MODE_INDY   }, /* d1 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* d2 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* d3 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* d4 */
    { MNEMONIC_CMP, ADDR_MODE_ZPX    }, /* d5 */
    { MNEMONIC_DEC, ADDR_MODE_ZPX    }, /* d6 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* d7 */
    { MNEMONIC_CLD, ADDR_MODE_IMP    }, /* d8 */
    { MNEMONIC_CMP, ADDR_MODE_ABSY   }, /* d9 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* da */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* db */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* dc */
    { MNEMONIC_CMP, ADDR_MODE_ABSX   }, /* dd */
    { MNEMONIC_DEC, ADDR_MODE_ABSX   }, /* de */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* df */
    { MNEMONIC_CPX, ADDR_MODE_IMM    }, /* e0 */
    { MNEMONIC_SBC, ADDR_MODE_INDX   }, /* e1 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* e2 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* e3 */
    { MNEMONIC_CPX, ADDR_MODE_ZP     }, /* e4 */
    { MNEMONIC_SBC, ADDR_MODE_ZP     }, /* e5 */
    { MNEMONIC_INC, ADDR_MODE_ZP     }, /* e6 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* e7 */
    { MNEMONIC_INX, ADDR_MODE_IMP    }, /* e8 */
    { MNEMONIC_SBC, ADDR_MODE_IMM    }, /* e9 */
    { MNEMONIC_NOP, ADDR_MODE_IMP    }, /* ea */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* eb */
    { MNEMONIC_CPX, ADDR_MODE_ABS    }, /* ec */
    { MNEMONIC_SBC, ADDR_MODE_ABS    }, /* ed */
    { MNEMONIC_INC, ADDR_MODE_ABS    }, /* ee */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* ef */
    { MNEMONIC_BEQ, ADDR_MODE_REL    }, /* f0 */
    { MNEMONIC_SBC, ADDR_MODE_INDY   }, /* f1 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* f2 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* f3 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* f4 */
    { MNEMONIC_SBC, ADDR_MODE_ZPX    }, /* f5 */
    { MNEMONIC_INC, ADDR_MODE_ZPX    }, /* f6 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* f7 */
    { MNEMONIC_SED, ADDR_MODE_IMP    }, /* f8 */
    { MNEMONIC_SBC, ADDR_MODE_ABSY   }, /* f9 */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* fa */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* fb */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }, /* fc */
    { MNEMONIC_SBC, ADDR_MODE_ABSX   }, /* fd */
    { MNEMONIC_INC, ADDR_MODE_ABSX   }, /* fe */
    { MNEMONIC_XXX, ADDR_MODE_UNDEF  }  /* ff */
};


static uint16_t  base;
static const char* cmd;
static uint8_t   opcode;
static uint8_t   param1;
static uint8_t   param2;


static void single_byte_opcode(void)
{
    uart_puthex_padded(2, opcode);
    uart_putnc(15, ' ');
    uart_puts(cmd);
}

static void two_bytes_opcode(void)
{
    param1 = mos6502_read_mem(base++);
    uart_puthex_padded(2, opcode);
    uart_putc(' ');
    uart_puthex_padded(2, param1);
    uart_putnc(12, ' ');
    uart_puts(cmd);
}

static void three_bytes_opcode(void)
{
    param1 = mos6502_read_mem(base++);
    param2 = mos6502_read_mem(base++);
    uart_puthex_padded(2, opcode);
    uart_putc(' ');
    uart_puthex_padded(2, param1);
    uart_putc(' ');
    uart_puthex_padded(2, param2);
    uart_putnc(9, ' ');
    uart_puts(cmd);
}

static void addr_mode_undef(void)
{
}

static void addr_mode_acc(void)
{
    uart_puts(" A");
}

static void addr_mode_imp(void)
{
}

static void addr_mode_imm(void)
{
    uart_puts(" #$");
    uart_puthex_padded(2, param1);
}

static void addr_mode_zp(void)
{
    uart_puts(" $");
    uart_puthex_padded(2, param1);
}

static void addr_mode_zpx (void)
{
    addr_mode_zp();
    uart_puts(",X");
}

static void addr_mode_zpy (void)
{
    addr_mode_zp();
    uart_puts(",Y");
}

static void addr_mode_abs(void)
{
    uart_puts(" $");
    uart_puthex_padded(4, (param2 << 8) | param1);
}

static void addr_mode_absx(void)
{
    addr_mode_abs();
    uart_puts(",X");
}

static void addr_mode_absy(void)
{
    addr_mode_abs();
    uart_puts(",Y");
}

static void addr_mode_absi(void)
{
    uart_puts(" ($");
    uart_puthex_padded(4, (param2 << 8) | param1);
    uart_putc(')');
}

static void addr_mode_indx(void)
{
    uart_puts(" ($");
    uart_puthex_padded(2, param1);
    uart_puts(",X)");
}

static void addr_mode_indy(void)
{
    uart_puts(" ($");
    uart_puthex_padded(2, param1);
    uart_puts("),Y");
}

static void addr_mode_rel(void)
{
    uart_puts(" $");

    if ( param1 < 0x80 )
    {
        uart_puthex_padded(4, base + param1);
    }
    else
    {
        uart_puthex_padded(4, base - (0x100 - param1) );
    }
}


uint16_t mos6502_dis(uint16_t start, uint16_t stop)
{
    const mos6502_instruction_t* pi;
    int len;

    base = start;

    while (base <= stop)
    {
        /* print address */
        uart_putc('$');
        uart_puthex_padded(4, base);
        uart_putc(' ');

        /* Get opcode and it's properties */
        opcode = mos6502_read_mem(base++);
        pi     = inst_map + opcode;
        cmd    = mnemonics[pi->mnemonic_idx];
        len    = addr_mode_length[pi->addr_mode_idx];

        /* Print opcode hexdump */
        switch (len)
        {
        case 1:
            single_byte_opcode();
            break;

        case 2:
            two_bytes_opcode();
            break;

        default:
            three_bytes_opcode();
        }

        /* Print opcode disassembly */
        addr_mode_fn[pi->addr_mode_idx]();
        uart_putcrlf();
    }

    return base;
}

