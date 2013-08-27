introduction
=============

target of this project is to provide a generic san adapter for eucalyptus (current support 3.3.0) \<br /\>
this san adapter comprise of three parties: \<br /\>
\<li\>a blockmanager for storage controller, name "clvm" \<br /\>
\<li\>a customized lvM lock which disable write operation for volume group metadata in node controller host \<br /\>
\<li\>some patched peal iscsi scripts which change behavior of discovering the exported block device in node controller host \<br /\>


  
