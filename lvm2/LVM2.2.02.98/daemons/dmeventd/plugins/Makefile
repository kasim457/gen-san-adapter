#
# Copyright (C) 2001-2004 Sistina Software, Inc. All rights reserved.
# Copyright (C) 2004-2005, 2011 Red Hat, Inc. All rights reserved.
#
# This file is part of LVM2.
#
# This copyrighted material is made available to anyone wishing to use,
# modify, copy, or redistribute it subject to the terms and conditions
# of the GNU General Public License v.2.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

srcdir = .
top_srcdir = ../../..
top_builddir = ../../..

SUBDIRS += lvm2

ifneq ("internal", "none")
  SUBDIRS += mirror
endif

ifneq ("internal", "none")
  SUBDIRS += snapshot
endif

ifneq ("internal", "none")
  SUBDIRS += raid
endif

ifneq ("none", "none")
  SUBDIRS += thin
endif

ifeq ($(MAKECMDGOALS),distclean)
  SUBDIRS = lvm2 mirror snapshot raid thin
endif

include $(top_builddir)/make.tmpl

snapshot: lvm2
mirror: lvm2
raid: lvm2
thin: lvm2
