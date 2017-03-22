#!/bin/sh
if [ -z $LFS ]; then
        echo ERROR: LFS variable unset or empty.
        exit -1
fi

mkdir -vp $LFS/tools/
ln -sv $LFS/tools/ /
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
chown -v lfs $LFS/tools/
chown -v lfs $LFS/sources/
