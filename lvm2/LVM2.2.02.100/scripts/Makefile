#
# Copyright (C) 2006-2011 Red Hat, Inc. All rights reserved.
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
top_srcdir = ..
top_builddir = ..

ifeq ("no", "yes")
	SOURCES = lvm2_activation_generator_systemd_red_hat.c
	TARGETS = lvm2_activation_generator_systemd_red_hat
endif

include $(top_builddir)/make.tmpl

ifeq ("no", "yes")
	DEPLIBS += $(top_builddir)/liblvm/liblvm2app.so $(top_builddir)/libdm/libdevmapper.so
	LDFLAGS += -L$(top_builddir)/liblvm
	LVMLIBS =  -ldevmapper
endif

ifeq ("", "yes")
	LVMLIBS += -ldevmapper-event
endif

SCRIPTS = lvmdump.sh lvmconf.sh vgimportclone.sh

ifeq ("yes", "yes")
	SCRIPTS += fsadm.sh
endif

ifeq ("yes", "yes")
	SCRIPTS += blkdeactivate.sh
endif

OCF_SCRIPTS =
ifeq ("no", "yes")
        OCF_SCRIPTS += VolumeGroup.ocf
endif

vpath %.sh $(srcdir)
vpath %.ocf $(srcdir)

%_install: %.sh
	$(INSTALL_PROGRAM) -D $< $(sbindir)/$(basename $(<F))

%_install: %.ocf
	$(INSTALL_DIR) $(ocf_scriptdir)
	$(INSTALL_SCRIPT) $< $(ocf_scriptdir)/$(basename $(<F))

install_lvm2: $(SCRIPTS:.sh=_install)

install_ocf: $(OCF_SCRIPTS:.ocf=_install)

install: install_lvm2 install_ocf

# FIXME Customise for other distributions
install_initscripts:
	$(INSTALL_DIR) $(initdir)
ifeq ("", "yes")
	$(INSTALL_SCRIPT) lvm2_monitoring_init_red_hat $(initdir)/lvm2-monitor
endif
ifeq ("no", "yes")
	$(INSTALL_SCRIPT) lvm2_lvmetad_init_red_hat $(initdir)/lvm2-lvmetad
endif
ifneq ("none", "none")
	$(INSTALL_SCRIPT) clvmd_init_red_hat $(initdir)/clvmd
endif
ifeq ("no", "yes")
	$(INSTALL_SCRIPT) cmirrord_init_red_hat $(initdir)/cmirrord
endif
ifeq ("yes", "yes")
	$(INSTALL_SCRIPT) blk_availability_init_red_hat $(initdir)/blk-availability
endif

lvm2_activation_generator_systemd_red_hat: $(OBJECTS) $(DEPLIBS)
	$(CC) -o $@ $(OBJECTS) $(LDFLAGS) $(LVMLIBS)

install_systemd_generators:
	$(INSTALL_DIR) $(systemd_generator_dir)
ifeq ("no", "yes")
	$(INSTALL_PROGRAM) lvm2_activation_generator_systemd_red_hat $(systemd_generator_dir)/lvm2-activation-generator
else
	@echo "WARNING: LVM2 activation systemd generator not installed." \
	      "It requires the LVM2 application library to be built as well."
endif

install_systemd_units:
	$(INSTALL_DIR) $(systemd_unit_dir)
ifeq ("", "yes")
	$(INSTALL_DATA) dm_event_systemd_red_hat.socket $(systemd_unit_dir)/dm-event.socket
	$(INSTALL_DATA) dm_event_systemd_red_hat.service $(systemd_unit_dir)/dm-event.service
	$(INSTALL_DATA) lvm2_monitoring_systemd_red_hat.service $(systemd_unit_dir)/lvm2-monitor.service
endif
ifeq ("yes", "yes")
	$(INSTALL_DATA) blk_availability_systemd_red_hat.service $(systemd_unit_dir)/blk-availability.service
endif
ifeq ("no", "yes")
	$(INSTALL_DATA) lvm2_lvmetad_systemd_red_hat.socket $(systemd_unit_dir)/lvm2-lvmetad.socket
	$(INSTALL_DATA) lvm2_lvmetad_systemd_red_hat.service $(systemd_unit_dir)/lvm2-lvmetad.service
endif

install_tmpfiles_configuration:
	$(INSTALL_DIR) $(tmpfiles_dir)
	$(INSTALL_DATA) lvm2_tmpfiles_red_hat.conf $(tmpfiles_dir)/lvm2.conf

DISTCLEAN_TARGETS += clvmd_init_red_hat cmirrord_init_red_hat \
		     lvm2_monitoring_init_red_hat lvm2_lvmetad_init_red_hat \
		     dm_event_systemd_red_hat.socket dm_event_systemd_red_hat.service \
		     lvm2_monitoring_systemd_red_hat.service \
		     lvm2_lvmetad_systemd_red_hat.socket lvm2_lvmetad_systemd_red_hat.service \
		     lvm2_tmpfiles_red_hat.conf blk_availability_init_red_hat \
		     blk_availability_systemd_red_hat.service \
		     blkdeactivate.sh
