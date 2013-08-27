#! /bin/sh

INSTALLDIR=usr/share/eucalyptus/

# honor the ENV variable if found otherwise look in root
if [ -z "$EUCALYPTUS" ] ; then
       EUCALYPTUS="/"
       if [ ! -e ${EUCALYPTUS}/etc/eucalyptus/eucalyptus.conf ] ; then
              EUCALYPTUS="/"
       fi
fi


# Read configuration variable file if it is present
if [ -r $EUCALYPTUS/etc/eucalyptus/eucalyptus.conf ]; then
        . $EUCALYPTUS/etc/eucalyptus/eucalyptus.conf
else
        echo "Cannot find eucalyptus configuration file!"
        exit 1
fi

if [ "$EUCALYPTUS" = "not_configured" ]; then
        echo "EUCALYPTUS not configured!"
        exit 1
fi

if [ -z "$EUCA_USER" ] ; then
        EUCA_USER="root"
fi


INSTALLDIR=$EUCALYPTUS/$INSTALLDIR
echo $INSTALLDIR


plfiles=`ls *.pl 2>/dev/null`
if test -z "$plfiles"; then
  echo "no perl files found"
  exit 1
fi 

echo "copy files: $plfiles to directory $INSTALLDIR"
tmpdir="/tmp/$$"
mkdir $tmpdir
cp -f *.pl $tmpdir/
chown $EUCA_USER:$EUCA_USER $tmpdir/* && chmod 0755 $tmpdir/*
mv $tmpdir/* $INSTALLDIR/
rm -rf $tmpdir

lvmlock=`ls *.so 2>/dev/null`
if test -z "$lvmlock"; then
  echo "no lvm lock library found found"
  exit 1
fi

echo "copy file: $lvmlock to directory /lib/" 
tmpdir="/tmp/$$"
mkdir $tmpdir
cp -f *.so $tmpdir/
chmod 0755 $tmpdir/*
mv $tmpdir/* /lib/
rm -rf $tmpdir


