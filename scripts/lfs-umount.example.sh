#!/bin/bash
/sbin/swapoff -v /dev/sdb1
RET=$?

umount -v $LFS
RET=$?
if [ $RET -ne 0 ]; then
	exit $RET
fi
