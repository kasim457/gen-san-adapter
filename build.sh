#! /bin/sh

workdir=`pwd`
build=$workdir/BUILD

. ./compile_lvm_lock.sh
cd $workdir
. ./compile_sc.sh

cp -f $workdir/src/node_controller/* $build/
cp -f $workdir/src/install_scripts/* $build/

cd $build && tar cvf gen-san-adapter.tar *
mv $build/gen-san-adapter.tar $workdir/


