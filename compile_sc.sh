#! /bin/sh

workdir=`pwd`
builddir=${workdir}/.build
if ! test -d $builddir; then
  mkdir $builddir
fi

if ! test -d $workdir/eucalyptus; then
  echo "there is no eucalyptus download it from github"
  git clone git://github.com/eucalyptus/eucalyptus --recursive
  cd $workdir/eucalyptus && git checkout 3.3.0
  cp -rf $workdir/lib $workdir/eucalyptus/clc/

fi

if test -d $workdir/lib; then
  cp -rf $workdir/lib $workdir/eucalyptus/clc/
fi

#build eucalyptus compile environment

#Download and save the following file
if ! test -e /opt/euca-WSDL2C.sh; then  
  echo "download euca0WSDL2C.sh"
  wget https://raw.github.com/eucalyptus/eucalyptus-rpmspec/master/euca-WSDL2C.sh
  cp euca-WSDL2C.sh  /opt/euca-WSDL2C.sh
  chmod +x /opt/euca-WSDL2C.sh
fi

#Build Eucalyptus
#===================
#First, make sure JAVA_HOME and EUCALYPTUS are defined. For example,
#make sure you are using java-1.7.0

export JAVA_HOME="/usr/lib/jvm/java-1.7.0/"
export JAVA="$JAVA_HOME/JRE/bin/java"
export EUCALYPTUS="/opt/eucalyptus"

cd $workdir/eucalyptus && ./configure '--with-axis2=/usr/share/axis2-*' \
--with-axis2c=/usr/lib64/axis2c --prefix=$EUCALYPTUS \
--with-apache2-module-dir=/usr/lib64/httpd/modules \
--with-db-home=/usr/pgsql-9.1 \
--with-wsdl2c-sh=/opt/euca-WSDL2C.sh

cp -rf $workdir/src/storage_controller/storage-san-clvm $workdir/eucalyptus/clc/modules/

#Make CLC
cd $workdir/eucalyptus/clc && make 
cp $workdir/eucalyptus/clc/target/eucalyptus-storage-san-clvm-*.jar $builddir/

if ! test -d $workdir/BUILD;then
  mkdir $workdir/BUILD
fi

# copy the compile file to BUILD directory
cp -f $builddir/* $workdir/BUILD
rm -rf $builddir


