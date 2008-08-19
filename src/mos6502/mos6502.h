/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef MOS6502_H
#define MOS6502_H

typedef struct mos6502_regs_s
{
    uint32_t    time;
    uint32_t    a;
    uint32_t    x;
    uint32_t    y;
    uint32_t    pc;
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

/* from mos6502.S */
void mos6502_reg_init();
void mos6502_store_regs(mos6502_regs_t* regs);
uint16_t mos6502_get_pc(void);
int mos6502_is_stopped(void);
uint8_t mos6502_read_mem(uint16_t address);

/* from mos6502_dis.c */
uint16_t mos6502_dis(uint16_t start, uint16_t stop);

#endif
