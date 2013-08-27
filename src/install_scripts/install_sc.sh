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

tarfiles=`ls *.jar 2>/dev/null`
if test -z "$tarfiles"; then
  echo "no jar file found"
  exit 1
fi 

echo "copy files: $tarfiles to directory $INSTALLDIR"
tmpdir="/tmp/$$"
mkdir $tmpdir
cp -f *.jar $tmpdir/
cd $tmpdir && chown $EUCA_USER:$EUCA_USER * && chmod 0644 *
mv $tmpdir/* $INSTALLDIR/
rm -rf $tmpdir
