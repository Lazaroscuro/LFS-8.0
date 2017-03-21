#!/bin/sh
if [ -z $LFS ]; then
        echo ERROR: LFS variable unset or empty.
        exit -1
fi

mkdir -p $LFS/sources/
chmod -v a+wt $LFS/sources/
wget -c --input-file=wget-list --directory-prefix=$LFS/sources
cp md5sums $LFS/sources/
pushd $LFS/sources
md5sum -c md5sums
popd
