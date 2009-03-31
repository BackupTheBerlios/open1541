#
# Makefile to download, build and install an arm-elf toolchain
# For documentation see below
#
# Copyright (C) 2008 Thomas Giesel
#
# This software is provided 'as-is', without any express or implied
# warranty.  In no event will the authors be held liable for any damages
# arising from the use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.
#
# Thomas Giesel skoe@directbox.com
#

# Tested in Ubuntu/Xubuntu/Kubuntu 7.10, 8.04, Cygwin, Gentoo
# 
# Following conditions must be met to sucessfully build the toolchain:
# - Be sure to have these packages installed
#     libmpfr-dev >= 2.3.0
#     libgmp3-dev >= 4.2
#     make        >= 3.81 (GNU Make)
#     gawk
#

here  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

build   := $(here)/build
archive := $(here)/archive
cleandirs :=

binutils  := binutils-2.19.51
gccfile   := gcc-core-4.3.3
gcc       := gcc-4.3.3
gdb       := gdb-6.8
insight   := insight-6.8

target    := arm-elf
prefix    := $(HOME)/cross/$(target)-$(binutils)-$(gcc)
# in case you need sudo for installing
sudo      :=
#sudo      := sudo

# this variable will be empty if we're not on cygwin
cygwin    := $(shell echo $$MACHTYPE | grep cygwin)

ifeq (x$(cygwin), x)
  path      := $(PATH):$(prefix)/bin
else
  # don't use all these windows paths
  path      := /bin:/usr/bin:$(prefix)/bin
endif

all: binutils gcc gdb insight


###############################################################################
### BINUTILS
###############################################################################

# we use an example executable to find out if it is installed already
.PHONY: binutils
binutils: $(prefix)/bin/$(target)-objdump

$(prefix)/bin/$(target)-objdump: $(build)/obj-$(binutils) $(build)/$(binutils)
	cd $(build)/obj-$(binutils) && $(build)/$(binutils)/configure \
		--target=$(target) --prefix=$(prefix) --disable-nls \
		--enable-interwork --disable-multilib --with-float=soft
	cd $(build)/obj-$(binutils) && make
	cd $(build)/obj-$(binutils) && $(sudo) make install

$(build)/$(binutils): $(archive)/$(binutils).tar.bz2
	cd $(build) && tar xjf $(archive)/$(binutils).tar.bz2

$(archive)/$(binutils).tar.bz2:
	mkdir -p $(archive)
	cd $(archive) && wget ftp://sourceware.org/pub/binutils/snapshots/$(binutils).tar.bz2
	touch $@

$(build)/obj-$(binutils):
	mkdir -p $(build)/obj-$(binutils)

cleandirs += $(build)/obj-$(binutils)

###############################################################################
### GCC
###############################################################################

# we use an example executable to find out if it is installed already
.PHONY: gcc
gcc: $(prefix)/bin/$(target)-gcc

$(prefix)/bin/$(target)-gcc: $(build)/obj-$(gcc) $(build)/$(gcc) | binutils
	cd $(build)/obj-$(gcc) && $(build)/$(gcc)/configure \
		--target=$(target) --prefix=$(prefix) --disable-nls \
		--disable-shared --enable-languages=c --disable-libssp \
		--enable-interwork --disable-multilib --with-float=soft
	cd $(build)/obj-$(gcc) && PATH=$(path) make
	cd $(build)/obj-$(gcc) && $(sudo) bash -c "PATH=$(path) make install"

$(build)/$(gcc): $(archive)/$(gccfile).tar.bz2
	cd $(build) && tar xjf $(archive)/$(gccfile).tar.bz2
	touch $@

$(archive)/$(gccfile).tar.bz2:
	mkdir -p $(archive)
	cd $(archive) && wget ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/$(gcc)/$(gccfile).tar.bz2

$(build)/obj-$(gcc):
	mkdir -p $(build)/obj-$(gcc)

cleandirs += $(build)/obj-$(gcc)

###############################################################################
### GDB
###############################################################################

# we use an example executable to find out if it is installed already
.PHONY: gdb
gdb: $(prefix)/bin/$(target)-gdb

$(prefix)/bin/$(target)-gdb: $(build)/obj-$(gdb) $(build)/$(gdb) | gcc
	cd $(build)/obj-$(gdb) && $(build)/$(gdb)/configure \
		--target=$(target) --prefix=$(prefix) --disable-nls \
		--disable-werror
	cd $(build)/obj-$(gdb) && PATH=$(path) make
	cd $(build)/obj-$(gdb) && $(sudo) bash -c "PATH=$(path) make install"

$(build)/$(gdb): $(archive)/$(gdb).tar.bz2
	cd $(build) && tar xjf $(archive)/$(gdb).tar.bz2
	touch $@

$(archive)/$(gdb).tar.bz2:
	mkdir -p $(archive)
	cd $(archive) && wget http://ftp.gnu.org/gnu/gdb/$(gdb).tar.bz2

$(build)/obj-$(gdb):
	mkdir -p $(build)/obj-$(gdb)

cleandirs += $(build)/obj-$(gdb)

###############################################################################
### Insight
###############################################################################

# we use an example executable to find out if it is installed already
.PHONY: insight
insight: $(prefix)/bin/$(target)-insight

$(prefix)/bin/$(target)-insight: $(build)/obj-$(insight) $(build)/$(insight) | gcc
	cd $(build)/obj-$(insight) && $(build)/$(insight)/configure \
		--target=$(target) --prefix=$(prefix) --disable-nls
	cd $(build)/obj-$(insight) && PATH=$(path) make
	cd $(build)/obj-$(insight) && $(sudo) bash -c "PATH=$(path) make install"

$(build)/$(insight): $(archive)/$(insight).tar.bz2
	cd $(build) && tar xjf $(archive)/$(insight).tar.bz2
	touch $@

$(archive)/$(insight).tar.bz2:
	mkdir -p $(archive)
	cd $(archive) && wget ftp://sourceware.org/pub/insight/releases/$(insight).tar.bz2

$(build)/obj-$(insight):
	mkdir -p $(build)/obj-$(insight)

cleandirs += $(build)/obj-$(insight)

###############################################################################
### Clean
###############################################################################

# clean removes everything which could be different on a new build
clean:
	rm -rf $(cleandirs)
