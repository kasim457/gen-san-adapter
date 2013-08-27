// -*- mode: C; c-basic-offset: 4; tab-width: 4; indent-tabs-mode: nil -*-
// vim: set softtabstop=4 shiftwidth=4 tabstop=4 expandtab:

/*************************************************************************
 * Copyright 2009-2013 Eucalyptus Systems, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see http://www.gnu.org/licenses/.
 *
 * Please contact Eucalyptus Systems, Inc., 6755 Hollister Ave., Goleta
 * CA 93117, USA or visit http://www.eucalyptus.com/licenses/ if you need
 * additional information or have any questions.
 *
 * This file may incorporate work covered under the following copyright
 * and permission notice:
 *
 *   Software License Agreement (BSD License)
 *
 *   Copyright (c) 2008, Regents of the University of California
 *   All rights reserved.
 *
 *   Redistribution and use of this software in source and binary forms,
 *   with or without modification, are permitted provided that the
 *   following conditions are met:
 *
 *     Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *     Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer
 *     in the documentation and/or other materials provided with the
 *     distribution.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *   FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *   COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *   INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *   BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *   ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *   POSSIBILITY OF SUCH DAMAGE. USERS OF THIS SOFTWARE ACKNOWLEDGE
 *   THE POSSIBLE PRESENCE OF OTHER OPEN SOURCE LICENSED MATERIAL,
 *   COPYRIGHTED MATERIAL OR PATENTED MATERIAL IN THIS SOFTWARE,
 *   AND IF ANY SUCH MATERIAL IS DISCOVERED THE PARTY DISCOVERING
 *   IT MAY INFORM DR. RICH WOLSKI AT THE UNIVERSITY OF CALIFORNIA,
 *   SANTA BARBARA WHO WILL THEN ASCERTAIN THE MOST APPROPRIATE REMEDY,
 *   WHICH IN THE REGENTS' DISCRETION MAY INCLUDE, WITHOUT LIMITATION,
 *   REPLACEMENT OF THE CODE SO IDENTIFIED, LICENSING OF THE CODE SO
 *   IDENTIFIED, OR WITHDRAWAL OF THE CODE CAPABILITY TO THE EXTENT
 *   NEEDED TO COMPLY WITH ANY SUCH LICENSES OR RIGHTS.
 ************************************************************************/

//! @file locking/euca_external_lock.c
/*
 * Locking functions for LVM.
 * The main purpose of this part of the library is to serialise LVM
 * management operations across a cluster.
 */

#include "lib.h"
#include "locking.h"
#include "locking_types.h"
#include "lvm-string.h"
#include "activate.h"
#include "toolcontext.h"
#include "memlock.h"
#include "defaults.h"
#include "lvmcache.h"
#include <signal.h>


static void (*_reset_file_fn) (void) = NULL;
static void (*_end_file_fn) (void) = NULL;
static int (*_lock_file_fn) (struct cmd_context * cmd, const char *resource,
			uint32_t flags) = NULL;
static int (*_lock_file_query_fn) (const char *resource, int *mode) = NULL;

static char EUCA_VG_PREFIX[] = "euca-sharedevice-vg";
static struct locking_type _file_locking;

int locking_init(int type, struct dm_config_tree *cft, uint32_t *flags);
int lock_resource(struct cmd_context *cmd, const char *resource, uint32_t flags);
void locking_end(void);

/**
 *  implementation
 */
static int _no_lock_resource(struct cmd_context *cmd, const char *resource,
			     uint32_t flags)
{
	switch (flags & LCK_SCOPE_MASK) {
	case LCK_VG:
		if (!strcmp(resource, VG_SYNC_NAMES))
			fs_unlock();
		break;
	case LCK_LV:
		switch (flags & LCK_TYPE_MASK) {
		case LCK_NULL:
			return lv_deactivate(cmd, resource);
		case LCK_UNLOCK:
			return lv_resume_if_active(cmd, resource, (flags & LCK_ORIGIN_ONLY) ? 1: 0, 0, (flags & LCK_REVERT) ? 1 : 0);
		case LCK_READ:
			return lv_activate_with_filter(cmd, resource, 0);
		case LCK_WRITE:
			return lv_suspend_if_active(cmd, resource, (flags & LCK_ORIGIN_ONLY) ? 1 : 0, 0);
		case LCK_EXCL:
			return lv_activate_with_filter(cmd, resource, 1);
		default:
			break;
		}
		break;
	default:
		log_error("Unrecognised lock scope: %d",
			  flags & LCK_SCOPE_MASK);
		return 0;
	}

	return 1;
}

static int _readonly_lock_resource(struct cmd_context *cmd,
				   const char *resource,
				   uint32_t flags)
{
    int euca_vg_prefix_len;
    char *vg_prefix; //[euca_vg_prefix_len + 1];
    int is_euca_vg = 0;
    
    euca_vg_prefix_len = strlen(EUCA_VG_PREFIX);
    vg_prefix = dm_zalloc(sizeof(char*) * euca_vg_prefix_len);
    //compare the vg name with euca vg prefix
    if (strlen(resource) >= euca_vg_prefix_len ) {
       strncpy(vg_prefix,resource,euca_vg_prefix_len);
       if (!strcmp(vg_prefix,EUCA_VG_PREFIX) ) {
          is_euca_vg = 1;
       }
    }
    dm_free(vg_prefix);
    if ((flags & LCK_TYPE_MASK) == LCK_WRITE &&
	    (flags & LCK_SCOPE_MASK) == LCK_VG &&
	    !(flags & LCK_CACHE) &&
	    strcmp(resource, VG_GLOBAL) && is_euca_vg) {
                         
		log_error("Read-only locking set. Write locks are prohibited.");
		return 0;
	}
	return  _lock_file_fn(cmd, resource, flags);
}

/* API entry point for LVM */
int locking_init(int type, struct dm_config_tree *cft, uint32_t *flags)
{	
	int ret = 0;
	struct cmd_context *cmd;
	cmd = dm_zalloc(sizeof(*cmd));
	cmd->cft = cft;
    ret = init_file_locking(&_file_locking,cmd,1);
    if (ret) {
       _reset_file_fn = _file_locking.reset_locking;
       _end_file_fn = _file_locking.fin_locking;
       _lock_file_fn = _file_locking.lock_resource;
    }
    dm_free(cmd);
    return ret;
}

int lock_resource(struct cmd_context *cmd, const char *resource, uint32_t flags)
{
    return _readonly_lock_resource(cmd,resource,flags);
}

void locking_end(void)
{
	_end_file_fn();
    return;
}

void reset_locking(void)
{
	_reset_file_fn();
    return;
}

int query_resource(struct cmd_context *cmd, const char *resource, uint32_t flags)
{
    return 0;
}


