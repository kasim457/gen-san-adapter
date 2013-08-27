#!/usr/bin/perl

# Copyright 2009-2013 Eucalyptus Systems, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses/.
#
# Please contact Eucalyptus Systems, Inc., 6755 Hollister Ave., Goleta
# CA 93117, USA or visit http://www.eucalyptus.com/licenses/ if you need
# additional information or have any questions.
#
# This file may incorporate work covered under the following copyright
# and permission notice:
#
#   Software License Agreement (BSD License)
#
#   Copyright (c) 2008, Regents of the University of California
#   All rights reserved.
#
#   Redistribution and use of this software in source and binary forms,
#   with or without modification, are permitted provided that the
#   following conditions are met:
#
#     Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
#     Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer
#     in the documentation and/or other materials provided with the
#     distribution.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#   FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#   COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#   INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#   BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
#   ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE. USERS OF THIS SOFTWARE ACKNOWLEDGE
#   THE POSSIBLE PRESENCE OF OTHER OPEN SOURCE LICENSED MATERIAL,
#   COPYRIGHTED MATERIAL OR PATENTED MATERIAL IN THIS SOFTWARE,
#   AND IF ANY SUCH MATERIAL IS DISCOVERED THE PARTY DISCOVERING
#   IT MAY INFORM DR. RICH WOLSKI AT THE UNIVERSITY OF CALIFORNIA,
#   SANTA BARBARA WHO WILL THEN ASCERTAIN THE MOST APPROPRIATE REMEDY,
#   WHICH IN THE REGENTS' DISCRETION MAY INCLUDE, WITHOUT LIMITATION,
#   REPLACEMENT OF THE CODE SO IDENTIFIED, LICENSING OF THE CODE SO
#   IDENTIFIED, OR WITHDRAWAL OF THE CODE CAPABILITY TO THE EXTENT
#   NEEDED TO COMPLY WITH ANY SUCH LICENSES OR RIGHTS.

$VGSCAN = untaint(`which vgscan`);
$LVDISPLAY = untaint(`which lvs`);
$LVCHANGE =  untaint(`which lvchange`);

sub trim
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    if(length($string)<1){
        return " ";
    }else{
        return $string;
    }    
}   
sub lv_is_actived {
	
	my ($attr) = @_;
	if ( length($attr) >=5 ) {
		$status = substr($attr,4,1);
    if ($status ne "a" ) {
    	return 0;
    } else {
    	return 1;
    }
  }
  return 0;
}
# enable_lv - scan the metadata of volume group to update the lvm2 data in kernel and active the
# the attached ebs volume (LV)
# @parameters
#   lvname  - name of logical volume 
# @return
#   lv_path - the full path of the activated logical volume
sub enable_lv {
	
	my ($lvname) = @_;
	my $find = 0;
	my $lv_attr="";
	my $lv_path="";
	run_cmd(1, 0, "$VGSCAN");
	my @outlines = run_cmd(1, 0, "$LVDISPLAY --separator , -o lv_name,lv_path,lv_attr,lv_tags");
	foreach(@outlines) {
		my ($name, $path,$attr,@tags) = split(",", $_);	  
		if( trim($name) eq $lvname ) {
			$lv_attr = trim($attr);
			$lv_path = trim($path);
			$find = 1;
			last;
		}
	}
  if( !$find ){
		return "";
	}
	
  # activate the logical volume 
  if (!is_null_or_empty($lv_attr) && !lv_is_actived($lv_attr) ) {
  	run_cmd(1,1,"$LVCHANGE -a y $lv_path");
  }
  return $lv_path;
}

# disable_lv - disactive the attached ebs volume (LV)
# @parameters
#   lvname  - name of logical volume 
# @return
#   lv_path - the full path of the activated logical volume
sub disable_lv {
	my ($lvname) = @_;
	my $find = 0;
	my $lv_attr="";
	my $lv_path="";
	my @outlines = run_cmd(1, 0, "$LVDISPLAY --separator , -o lv_name,lv_path,lv_attr,lv_tags");
	foreach(@outlines) {
		my ($name, $path,$attr,@tags) = split(",", $_);	  
		if( trim($name) eq $lvname ) {
			$lv_attr = trim($attr);
			$lv_path = trim($path);
			$find = 1;
			last;
		}
	}
  if( !$find ){
		return "";
	}
  # dactivate the logical volume 
  if (!is_null_or_empty($lv_attr) && lv_is_actived($lv_attr) ) {
  	run_cmd(1,0,"$LVCHANGE -a n $lv_path");
  }
}

# get_lv - find the attached LV
# @parameters
#   lvname  - name of logical volume 
# @return
#   lv_path - the full path of the activated logical volume
sub get_lv {
	
	my ($lvname) = @_;
	my $find = 0;
	my $lv_attr="";
	my $lv_path="";

	my @outlines = run_cmd(1, 0, "$LVDISPLAY --separator , -o lv_name,lv_path,lv_attr,lv_tags");
	foreach(@outlines) {
		my ($name, $path,$attr,@tags) = split(",", $_);	  
		if( trim($name) eq $lvname ) {
			return trim($path);
		}
	}
  return "";
}

# scan_lvm_for_clvm - sync the volume group data and activate LV according to connection string returned
# from SC (pattern:<pass>,<iface>,<sc ip>,<store name>). in the connection string, the variable <pass> is"CLVM"
# and <iface> is "CLVM",
# @parameters
#   pass  - the password, it should be "CLVM"
#   paths - "<iface>,<sc ip>,<lv name>
# @return
#   print the path of LV into STDOUT and error message into STDERR

sub scan_lvm_for_clvm {
	my ($pass,@paths) = @_;
	if (@paths >=3 ){
		$iface = shift(@paths);
		$ip = shift(@paths);
		$lvname = shift(@paths);
		if ( (uc($pass) eq "CLVM") && (uc($iface) eq "CLVM") ) {
			
		  # try to scan the volume group changes and activate the lv
		  for ($i=0;$i<3;$i++) {
		  	$lv_path = enable_lv($lvname);
		  	if(!is_null_or_empty($lv_path)) {
		  		print "$lv_path";
		  		do_exit(0);
		  	}	
		  }
		  # can't synchronize the metadata LVM or find the LV
		  print STDERR "Unable to find or activate the LV:".$lvname."\n";
      do_exit(1);
		}
		
	}
}

# disable_lvm_for_clvm - deactivate LV according to connection string 
# from SC (pattern:<pass>,<iface>,<sc ip>,<store name>). in the connection string, the variable <pass> is"CLVM"
# and <iface> is "CLVM",
# @parameters
#   pass  - the password, it should be "CLVM"
#   paths - "<iface>,<sc ip>,<lv name>
# @return
#   print error message into STDERR

sub disable_lv_for_clvm {
	my ($pass,@paths) = @_;
	if (@paths >=3 ){
		$iface = shift(@paths);
		$ip = shift(@paths);
		$lvname = shift(@paths);
		if ( (uc($pass) eq "CLVM") && (uc($iface) eq "CLVM") ) {
			disable_lv($lvname);	
		  do_exit(0);	 
		}			
	}
	
# disable_lvm_for_clvm - get LV according to connection string 
# connection string pattern:<pass>,<iface>,<sc ip>,<store name>). 
# in the connection string of CLVM manager, the variable <pass> is"CLVM" and <iface> is "CLVM",
# @parameters
#   pass  - the password, it should be "CLVM"
#   paths - "<iface>,<sc ip>,<lv name>
# @return
#   print error message into STDERR

sub get_lv_for_clvm {
	my ($pass,@paths) = @_;
	if (@paths >=3 ){
		$iface = shift(@paths);
		$ip = shift(@paths);
		$lvname = shift(@paths);
		if ( (uc($pass) eq "CLVM") && (uc($iface) eq "CLVM") ) {
			$lv_path = get_lv($lvname);	 
			if(!is_null_or_empty($lv_path)) {
				print $lv_path;
				do_exit(0);
			}
			# can't  find the LV
		  print STDERR "Unable to find the LV:".$lvname."\n";
		  do_exit(1);	
		}		
	}
}
	
}
