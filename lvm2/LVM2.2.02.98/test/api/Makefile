#
# Copyright (C) 2009-2012 Red Hat, Inc. All rights reserved.
#
# This file is part of LVM2.
#
# This copyrighted material is made available to anyone wishing to use,
# modify, copy, or redistribute it subject to the terms and conditions
# of the GNU General Public License v.2.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

srcdir = .
top_srcdir = ../..
top_builddir = ../..

TARGETS =
ifeq ("no", "yes")
TARGETS += test
SOURCES = test.c

TARGETS += \
	lvtest.t \
	percent.t \
	pe_start.t \
	thin_percent.t \
	vgtest.t

SOURCES2 = \
	lvtest.c \
	percent.c \
	pe_start.c \
	thin_percent.c \
	vgtest.c

endif

include $(top_builddir)/make.tmpl

DEFS += -D_REENTRANT
DEPLIBS += $(top_builddir)/liblvm/liblvm2app.so $(top_builddir)/libdm/libdevmapper.so
LDFLAGS += -L$(top_builddir)/liblvm
LVMLIBS =  -ldevmapper

ifeq ("", "yes")
       LVMLIBS += -ldevmapper-event
       LDFLAGS += -L$(top_builddir)/daemons/dmeventd
endif

LVMLIBS += $(LIBS)

%.t: %.o $(DEPLIBS)
	$(CC) -o $@ $(<) $(LDFLAGS) $(LVMLIBS)

test: $(OBJECTS) $(DEPLIBS)
	$(CC) -o $@ $(OBJECTS) $(LDFLAGS) $(LVMLIBS) $(READLINE_LIBS)

Makefile: $(srcdir)/Makefile.in $(top_builddir)/config.status
	cd $(top_builddir) && $(SHELL) ./config.status test/api/Makefile
