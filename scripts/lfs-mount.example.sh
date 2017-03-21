#!/bin/bash
if [ -z $LFS ]; then
	echo ERROR: LFS variable unset or empty.
	exit -1
fi

mount -v -t ext4 /dev/sdb2 $LFS
RET=$?
if [ $RET -ne 0 ]; then
	exit $RET
fi

MPTS=`mount | grep $LFS`
PROBLEMS=`echo $MPTS | grep -P "nosuid|nodev"`

/sbin/swapon -v /dev/sdb1
RET=$?
if [ $RET -ne 0 ]; then
	umount $LFS
	exit $RET
fi

#echo Mount points: $MPTS
if [ -n "$PROBLEMS" ]; then
        echo WARNING: You must avoid nosuid and nodev options
	echo Check: $PROBLEMS
fi
