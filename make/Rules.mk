#
# Rules.mk - Rules for creating files
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

#############################################################################
# Create .o in objdir from .c in the corresponding srcdir
#
$(objdir)%.o: $(srcdir)%.c | $(objdir)/autoconf.h
	echo 'compiling $(notdir $<) ...'
	mkdir -p $(dir $@)
	$(CC) -c -MD -MT $@ -MF $(objdir)$*.d \
		 $(CFLAGS) $(DEFINE) $(INCLUDE) -g -o $@ $<

#############################################################################
# Create .o in objdir from .S in the corresponding srcdir
#
$(objdir)%.o: $(srcdir)%.S | $(objdir)/autoconf.h
	echo 'compiling $(notdir $<) ...'
	mkdir -p $(dir $@)
	$(CC) -c -MD -MT $@ -MF $(objdir)$*.d \
		$(CFLAGS) $(DEFINE) $(INCLUDE) -g -o $@ $<

#############################################################################
# Create .o from .s
#
%.o: %.s | $(objdir)/autoconf.h
	echo 'compiling $(notdir $<) ...'
	mkdir -p $(dir $@)
	$(CC) -c -MD -MT $@ -MF $(objdir)$*.d \
		$(CFLAGS) $(DEFINE) $(INCLUDE) -g -o $@ $<

#############################################################################
# Create .s in objdir from .bin in the corresponding srcdir
#
$(objdir)%.s: $(srcdir)%.bin
	echo .text > $@
	echo .global $(*F) >> $@
	echo $(*F): >> $@
	hexdump -v -e '".byte " 1/1 "0x%02x\n"' $< >> $@

#############################################################################
# Create .s from .bin
#
%.s: %.bin
	echo .text > $@
	echo .global $(*F) >> $@
	echo $(*F): >> $@
	hexdump -v -e '".byte " 1/1 "0x%02x\n"' $< >> $@

#############################################################################
# Create .hex from elf-file in same directory
#
%.hex: %
	echo 'creating $(notdir $@) ...'
	$(OBJCOPY) -O ihex $< $@
	$(SIZE) $<

#############################################################################
# Generate autoconf.h from config
#
$(objdir)/autoconf.h: $(config)
	mkdir -p $(dir $@)
	sed -f $(scriptdir)/conf2h.sed $(config) > $(objdir)/autoconf.h
#    gawk -f $(scriptdir)/conf2h.awk $(config) > $(objdir)/autoconf.h
