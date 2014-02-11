#! /bin/sh

workdir=`pwd`
builddir=${workdir}/.build
mkdir $builddir

LVMVERSION=LVM2.2.02.100

#copy the lock source code to LVM2 locking dir
echo "===========copy the lock source code to LVM2 locking dir=============================="
cp -f $workdir/src/euca_lvm_lock/* $workdir/lvm2/$LVMVERSION/lib/locking/

echo "===========setup/compile LVM2========================================================="
cd $workdir/lvm2/$LVMVERSION && ./configure --prefix=$builddir --with-cluster=shared && make clean && make

echo "===========compile euca lvm lock======================================================"
cd $workdir/lvm2/$LVMVERSION/lib/locking && make -f Makefile.euca

cp -f $workdir/lvm2/$LVMVERSION/lib/locking/liblvm2euca*.so $builddir/
libs=`ls $workdir/lvm2/$LVMVERSION/lib/locking/liblvm2euca*.so`
echo "$libs are copied to directory $builddir"

if ! test -d $workdir/BUILD;then
  mkdir $workdir/BUILD
fi

# copy the compile file to BUILD directory
cp -f $builddir/* $workdir/BUILD
rm -rf $builddir
