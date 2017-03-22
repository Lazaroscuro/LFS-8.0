#!/bin/sh
sh lfs-mount.sh
RET=$?
if [ $RET -ne 0 ]; then
	echo ERROR: mount \(you must create lfs-mount.sh and lfs-unmount.sh\)
	exit $RET
fi

if [ -z $LFS ]; then
        echo ERROR: LFS variable unset or empty.
        exit -1
fi

sh ./sources.sh

sh lfs-umount.sh
RET=$?
if [ $RET -ne 0 ]; then
	echo ERROR: unmount \(you must create lfs-mount.sh and lfs-unmount.sh\)
	exit $RET
fi

echo done!
