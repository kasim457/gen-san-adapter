introduction
=============

target of this project is to provide a generic san adapter for eucalyptus (current support 3.3.0) <br/>
this san adapter comprise of three parties: <br/>
<li>a blockmanager for storage controller, name "clvm" <br/>
<li>a customized lvM lock which disable write operation for volume group metadata in node controller host <br/>
<li>some patched peal iscsi scripts which change behavior of discovering the exported block device in node controller host <br/>
<br/>
For detail design, please refer to design documents <br/>
This adapter only support eucalyptus 3.3.0 (propably 3.3.0.1 but not testing until now). <br/>

compile
===============
All source codes of this project now can be compiled in centos 6.3 or 6.4, before you begin to compile this project <br/>
make sure you already has a environment which can compile eucalypyus 3.3.0. for example resolve all build dependency<br/>
  
Following are compiling steps: <br/>
1) download the source codes from github <br/>
\#git clone  <br/>
<br/>
2) run the build script <br>
\#cd gen-san-adapter && ./build.sh <br/>
<br>
a tarball "gen-san-adapter.tar" will be generated in this directory.<br/>

install
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
<br>
configuration
===============
1) In storage controller <br/>
take a example that you have cluster "cluster001" and you had SAN device attached to SC at /dev/sdb
\# euca-modify-property -p storage.cluster001.blockmanager=clvm
\# euca-modify-property -p storage.cluster001.sharedevice=/dev/sdb
<br/>
2) In NC controller <br/>
At first, you need to change the lvm configuration <br>
please refer the example of lvm.conf, 













  
