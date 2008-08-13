#
# Makefile
#
# (c) 2008 Thomas Giesel <skoe@directbox.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License only.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

ifeq ($(MAKECMDGOALS),simulate)
platform     ?= skyeye
else
platform     ?= lpc2134
endif

add_path     ?= /opt/arm-elf-binutils-2.18.50-gcc-4.3.0/bin
serial_port  ?= /dev/ttyUSB0

project_root := $(abspath $(shell echo `pwd`)/..)
scriptdir    := $(project_root)/scripts
tooldir      := $(project_root)/tools
srcdir       := $(project_root)/src
incdir       := $(project_root)/include
objdir       := $(project_root)/obj-$(platform)

lpcflash     := $(project_root)/tools/lpcflash/lpcflash


# remove built-in rules to make debugging easier
.SUFFIXES:
% : %

# mark all targets as secondary to prevent their deletion
.SECONDARY:

ifneq ($(add_path), )
PATH := $(PATH):$(add_path)
endif

#############################################################################
# Default target
#
# This is the default target, it must be the first in the file.
#
.PHONY: all
all: world


#############################################################################
# Options
#

INCLUDE := -I$(incdir)
INCLUDE += -I$(srcdir)
INCLUDE += -I$(srcdir)/c1541
INCLUDE += -I$(srcdir)/mos6502

CFLAGS  := -Wall -Wno-trigraphs -Werror -Os -Wall
CFLAGS  += --param max-inline-insns-auto=3
CFLAGS  += 
CFLAGS  += -march=armv4 -mtune=arm7tdmi -std=c99

LDFLAGS := -N -p -X -T$(scriptdir)/lpc2134.ld

include $(platform).options

#############################################################################
# Objects

obj := $(objdir)/open1541.o
obj += $(objdir)/startup.o
obj += $(objdir)/uart.o
obj += $(objdir)/timer.o
obj += $(objdir)/util-ll.o
obj += $(objdir)/cli.o
obj += $(objdir)/c1541/c1541.o
obj += $(objdir)/mos6502/mos6502.o
obj += $(objdir)/mos6502/mos6502_flags.o
obj += $(objdir)/mos6502/mos6502_compare.o
obj += $(objdir)/mos6502/mos6502_jmp.o
obj += $(objdir)/mos6502/mos6502_transfer.o
obj += $(objdir)/mos6502/mos6502_arith.o
obj += $(objdir)/mos6502/mos6502_logic.o
obj += $(objdir)/mos6502/mos6502_mem.o
obj += $(objdir)/mos6502/mos6502_if.o
obj += $(objdir)/mos6502/mos6502_dis.o
obj += $(objdir)/libc/memset.o
obj += $(objdir)/libc/memmove.o
obj += $(objdir)/libc/strlen.o
obj += $(objdir)/libc/memcmp.o
obj += $(objdir)/libc/strcmp.o
obj += $(objdir)/libc/strncmp.o
obj += $(objdir)/libc/memcpy.o
obj += $(objdir)/libc/strcpy.o
#obj += $(objdir)/d1541II.o

extra_obj := `$(CC) -print-libgcc-file-name`

#############################################################################
# Targets
#
.PHONY: world
world: $(objdir)/open1541.hex

$(objdir)/open1541: $(obj)
	$(LD) $(LDFLAGS) -o $@ $(obj) $(extra_obj)

.PHONY: simulate
simulate: $(objdir)/open1541
	$(SHELL) -c "$(INSIGHT) $(objdir)/open1541 & \
		skyeye -c $(scriptdir)/skyeye.conf -e $(objdir)/open1541 -d"

# UART doesn't work in this mode?
#.PHONY: run
#run: $(objdir)/open1541
#	skyeye -c $(scriptdir)/skyeye.conf -e $(objdir)/open1541

.PHONY: flash
flash: $(lpcflash) $(objdir)/open1541.hex
	$(lpcflash) -p $(serial_port) $(objdir)/open1541.hex

$(lpcflash):
	make -C $(dir $@)

#############################################################################
# Automatic dependencies
#
-include $(obj:.o=.d)

#$(obj): $(wildcard $(incdir)/*)
#$(srcdir)/mos6502/mos6502.S: $(srcdir)/mos6502/mos6502_mem.S $(srcdir)/mos6502/mos6502_defs.S

# include the rules
include Rules.mk
