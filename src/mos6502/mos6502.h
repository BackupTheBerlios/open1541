/*
 * mos6502 - a 6502 emulator
 *
 * (c) 2008, 2009 Thomas Giesel
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

#ifndef MOS6502_H
#define MOS6502_H

#include <stdint.h>

typedef struct mos6502_regs_s
{
    uint32_t    time;
    uint32_t    a;
    uint32_t    x;
    uint32_t    y;
    uint32_t    sp;
    uint32_t    pc;
    uint32_t    flags;
}
mos6502_regs_t;

/* from mos6502_if.c */
void mos6502_reset(void);
void mos6502_dump_regs(void);
uint16_t mos6502_get_pc(void);
void mos6502_stop(void);
void mos6502_step(void);
void mos6502_run(void);
void mos6502_dump_mem(uint16_t start, uint16_t stop);
void mos6502_fill_mem(uint16_t from, uint16_t to, uint8_t val);

#if CONFIG_BREAKPOINTS > 0
void mos6502_show_breakpoints(void);
int mos6502_set_breakpoint(uint16_t addr);
void mos6502_rm_breakpoint(uint16_t addr);
#endif

/* from mos6502.S */
extern uint16_t mos6502_bp;
void mos6502_reg_init();
void mos6502_store_regs(mos6502_regs_t* regs);
uint16_t mos6502_get_pc(void);
int mos6502_is_stopped(void);
uint8_t mos6502_read_mem(uint16_t address);
uint8_t mos6502_write_mem(uint16_t address, uint8_t val);
void mos6502_irqsim(uint32_t i);

/* from mos6502_dis.c */
uint16_t mos6502_dis(uint16_t start, uint16_t stop);

#endif
