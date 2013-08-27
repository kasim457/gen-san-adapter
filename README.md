Introduction
=============

target of this project is to provide a generic san adapter for eucalyptus (current support 3.3.0) <br/>
this san adapter comprise of three parties: <br/>
<li>a blockmanager for storage controller, name "clvm" <br/>
<li>a customized lvM lock which disable write operation for volume group metadata in node controller host <br/>
<li>some patched peal iscsi scripts which change behavior of discovering the exported block device in node controller host <br/>
<br/>
For detail design, please refer to design documents <br/>
This adapter only support eucalyptus 3.3.0 (propably 3.3.0.1 but not testing until now). <br/>
Compiling
===============
All source codes of this project now can be compiled in centos 6.3 or 6.4, before you begin to compile this project <br/>
make sure you already has a environment which can compile eucalypyus 3.3.0. for example resolve all build dependency<br/>
  
Following are compiling steps: <br/>
1) download the source codes from github <br/>
\#git clone  <br/>
<br/>
2) run the build script <br>
\#cd gen-san-adapter && ./build.sh <br/>
A tarball "gen-san-adapter.tar" will be generated in this directory.<br/>
Installation
================
This generic san adapter need to be installed after you install eucalyptus 3.3.0 and before cloud are initialized  

You can have a install package "gen-san-adapter.tar" by compiling the source codes <br/>
or download from github "https://https://github.com/nathanxu/gen-san-adapter-tarball" <br/>
1) In storage controller <br/>
\# tar vxf gen-san-adapter.3.3.0.tar <br/>
\# ./install_sc.sh <br/>
A jar file will be installed to directory $EUCALYPTUS/usr/share/eucalyptus <br/>
2) In node controller <br/>
\# tar vxf gen-san-adapter.3.3.0.tar <br/>
\# ./install_nc.sh <br/>
A lvm lock library will be installed to /lib and perl scripts will be installed into $EUCALYPTUS/usr/share/eucalyptus<br/>
Configuration
===============
###1) In storage controller <br/>
take a example that you have cluster "cluster001" and you had SAN device attached to SC at /dev/sdb
\# euca-modify-property -p storage.cluster001.blockmanager=clvm
\# euca-modify-property -p storage.cluster001.sharedevice=/dev/sdb
<br/>

###2) In NC controller <br/>

At first, you need to change the lvm configuration <br>
please refer the example of lvm.conf and edit /etc/lvm/lvm.conf by change or adding following items<br/>

###Configure /etc/lvm/lvm.conf file <br>
in global section. change the locking type and locking library
<br/>
...<br/>
global { <br/>
&nbsp;&nbsp;...<br/>
&nbsp;&nbsp;\# Type of locking to use. Defaults to local file-based locking (1). <br/>
&nbsp;&nbsp;\# Turn locking off by setting to 0 (dangerous: risks metadata corruption <br/>
&nbsp;&nbsp;\# if LVM2 commands get run concurrently). <br/>
&nbsp;&nbsp;\# Type 2 uses the external shared library locking_library. <br/>
&nbsp;&nbsp;\# Type 3 uses built-in clustered locking. <br/>
&nbsp;&nbsp;\# Type 4 uses read-only locking which forbids any operations that might <br/>
&nbsp;&nbsp;\# change metadata. <br/>
&nbsp;&nbsp;\#locking_type = 1 <br/>
&nbsp;&nbsp;locking_type = 2 <br/>
&nbsp;&nbsp;... <br/>
&nbsp;&nbsp;\# The external locking library to load if locking_type is set to 2. <br/>
&nbsp;&nbsp;\#   locking_library = "liblvm2clusterlock.so" <br/>
&nbsp;&nbsp;locking_library = "/lib/liblvm2eucalock.so" <br/>
&nbsp;&nbsp;.... <br/>
}<br/>
in activation section, change the volume group filter. <br/>
activation {<br/>
&nbsp;&nbsp;...<br/>
&nbsp;&nbsp;\# If volume_list is defined, each LV is only activated if there is a <br/>
&nbsp;&nbsp;\# match against the list.<br/>
&nbsp;&nbsp;\# "vgname" and "vgname/lvname" are matched exactly.<br/>
&nbsp;&nbsp;\# "@tag" matches any tag set in the LV or VG.<br/>
&nbsp;&nbsp;\# "@*" matches if any tag defined on the host is also set in the LV or VG<br/>
&nbsp;&nbsp;\#<br/>
&nbsp;&nbsp;\#volume_list = [ "vg1", "vg2/lvol1", "@tag1", "@*" ]<br/>
&nbsp;&nbsp;volume_list = [ "@*" ]<br/>
&nbsp;&nbsp;...<br/>
}<br/>
in item volume_list, you should add all existing vgs which include non-san pv <br/>
for example, in the NC host, if you have volume groups /dev/vg1 and /dev/vg2 which use the local attached disks <br/>
you should configure the volume_list item as: <br>
&nbsp;&nbsp;&nbsp;volume_list = [ "vg1","vg2","@*" ]<br/>
<br/>
In tags sections, add the following items: <br/>
...<br/>
tags { <br/>
&nbsp;&nbsp;...<br/>
&nbsp;&nbsp;hosttags = 1 <br/>
&nbsp;&nbsp;@192.168.1.101{} #replace "192.168.1.101" as the node controller registry IP <br/>
&nbsp;&nbsp;...<br/>
}<br/>
###Configure /etc/iscsi/initiatorname.iscsi file <br>
configure the InitatorName as "InitiatorName=iqn.1994-05.com.redhat:your_node_ctronller_ip<br/>
for example, your node controller will be registered in cloud with IP 191.168.1.101, then configure<br>
the InitiatorName as: <br/>
InitiatorName=iqn.1994-05.com.redhat:192.168.1.101<br/>






  
