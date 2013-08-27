/*******************************************************************************
 *Copyright (c) 2009  Eucalyptus Systems, Inc.
 * 
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, only version 3 of the License.
 * 
 * 
 *  This file is distributed in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 *  for more details.
 * 
 *  You should have received a copy of the GNU General Public License along
 *  with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 *  Please contact Eucalyptus Systems, Inc., 130 Castilian
 *  Dr., Goleta, CA 93101 USA or visit <http://www.eucalyptus.com/licenses/>
 *  if you need additional information or have any questions.
 * 
 *  This file may incorporate work covered under the following copyright and
 *  permission notice:
 * 
 *    Software License Agreement (BSD License)
 * 
 *    Copyright (c) 2008, Regents of the University of California
 *    All rights reserved.
 * 
 *    Redistribution and use of this software in source and binary forms, with
 *    or without modification, are permitted provided that the following
 *    conditions are met:
 * 
 *      Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * 
 *      Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 * 
 *    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 *    IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 *    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *    PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 *    OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *    PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *    NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. USERS OF
 *    THIS SOFTWARE ACKNOWLEDGE THE POSSIBLE PRESENCE OF OTHER OPEN SOURCE
 *    LICENSED MATERIAL, COPYRIGHTED MATERIAL OR PATENTED MATERIAL IN THIS
 *    SOFTWARE, AND IF ANY SUCH MATERIAL IS DISCOVERED THE PARTY DISCOVERING
 *    IT MAY INFORM DR. RICH WOLSKI AT THE UNIVERSITY OF CALIFORNIA, SANTA
 *    BARBARA WHO WILL THEN ASCERTAIN THE MOST APPROPRIATE REMEDY, WHICH IN
 *    THE REGENTS' DISCRETION MAY INCLUDE, WITHOUT LIMITATION, REPLACEMENT
 *    OF THE CODE SO IDENTIFIED, LICENSING OF THE CODE SO IDENTIFIED, OR
 *    WITHDRAWAL OF THE CODE CAPABILITY TO THE EXTENT NEEDED TO COMPLY WITH
 *    ANY SUCH LICENSES OR RIGHTS.
 *******************************************************************************/
/*
 *
 * Author: Zach Hill zach@eucalyptus.com
 */

package com.eucalyptus.storage;

import org.apache.log4j.Logger;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.eucalyptus.system.BaseDirectory;
import com.eucalyptus.util.EucalyptusCloudException;
import com.eucalyptus.util.StorageProperties;

import edu.ucsb.eucalyptus.util.SystemUtil;


public class CLVMWrapper {
	
	Logger LOG = Logger.getLogger(CLVMWrapper.class);
	private static final String EUCA_ROOT_WRAPPER = BaseDirectory.LIBEXEC.toString() + "/euca_rootwrap";
	
	public static boolean addHostTag(String lvName, String hostTag) throws EucalyptusCloudException {
		boolean success = false;
		
		if (hostTagExists(lvName, hostTag)){
			return true;
		}
		String returnValue = SystemUtil.run(new String[]{StorageProperties.EUCA_ROOT_WRAPPER, "lvchange","--addtag",hostTag,lvName});
		if(returnValue.length() > 0) {
			success = true;
		}
		return success;
	}
	
	public static boolean delHostTag(String lvName, String hostTag) throws EucalyptusCloudException {
		boolean success = false;
		
		if (!hostTagExists(lvName, hostTag)){
			return true;
		}
		String returnValue = SystemUtil.run(new String[]{StorageProperties.EUCA_ROOT_WRAPPER, "lvchange","--deltag",hostTag,lvName});
		if(returnValue.length() > 0) {
			success = true;
		}
		return success;
	}
	
	public static String[] getHostTag(String lvName) throws EucalyptusCloudException {
		String returnValue = SystemUtil.run(new String[]{StorageProperties.EUCA_ROOT_WRAPPER, "lvs","--rows", "--separator",":","-o", "lv_tags",lvName});
		Pattern volumeGroupPattern = Pattern.compile("(?s:.*LV Tags:)(.*)\n.*");
		Matcher m = volumeGroupPattern.matcher(returnValue);
		if(m.find() && !m.group(1).equals("")) {
			return m.group(1).trim().split(",");
		}
		return null;
	}
	
	public static boolean hostTagExists(String lvName, String hostTag) throws EucalyptusCloudException {
		
		boolean returnValue = false;
		String[] tags = CLVMWrapper.getHostTag(lvName);
		if (tags !=null && tags.length > 0 )
			for (int i = 0; i< tags.length; i++) {
				if ( tags[i].equals(hostTag) )
					return true;
			}
		return false;		
	}
	
	public static boolean delAllHostTag(String lvName) throws EucalyptusCloudException {
		boolean success = true;
		String[] tags = CLVMWrapper.getHostTag(lvName);
		for (int i=0;i<tags.length; i++) {
			if(!tags[i].startsWith("vol")) {
				String returnValue= SystemUtil.run(new String[]{StorageProperties.EUCA_ROOT_WRAPPER, "lvchange","--deltag",tags[i],lvName});
				if (returnValue==null || returnValue.isEmpty() )
					success = false;
			}
		}
		return success;
	}
	
	

}
