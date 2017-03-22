#!/bin/bash
export MAKEFLAGS='-j 8'
cd $LFS/sources

# Libstdc++
tar -xf gcc-6.3.0.tar.bz2
pushd gcc-6.3.0

mkdir -v build && cd build
time {
	../libstdc++-v3/configure \
	--host=$LFS_TGT \
	--prefix=/tools \
	--disable-multilib \
	--disable-nls \
	--disable-libstdcxx-threads \
	--disable-libstdcxx-pch \
	--with-gxx-include-dir=/tools/$LFS_TGT/include/c++/6.3.0 \
	&& make \
	&& make install
}

popd
rm -rf gcc-6.3.0

# Binutils (pass 2)
tar -xf binutils-2.27.tar.bz2
pushd binutils-2.27

mkdir -v build && cd build
time {
	CC=$LFS_TGT-gcc \
	AR=$LFS_TGT-ar \
	RANLIB=$LFS_TGT-ranlib \
	../configure \
	--prefix=/tools \
	--disable-nls \
	--disable-werror \
	--with-lib-path=/tools/lib \
	--with-sysroot \
	&& make \
	&& make install \
	&& make -C ld clean \
	&& make -C ld LIB_PATH=/usr/lib:/lib \
	&& cp -v ld/ld-new /tools/bin
}

popd
rm -rf binutils-2.27

# GCC (pass 2)
tar -xf gcc-6.3.0.tar.bz2
pushd gcc-6.3.0

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
	`dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

for file in gcc/config/{linux,i386/linux{,64}}.h
do
	cp -uv $file{,.orig}
	sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
		-e 's@/usr@/tools@g' $file.orig > $file
	echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
	touch $file.orig
done

case $(uname -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib/' \
			-i.orig gcc/config/i386/t-linux64
	;;
esac

tar -xf ../mpfr-3.1.5.tar.xz
mv -v mpfr-3.1.5 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.0.3.tar.gz
mv -v mpc-1.0.3 mpc

mkdir -v build && cd build
time {
	CC=$LFS_TGT-gcc \
	CXX=$LFS_TGT-g++ \
	AR=$LFS_TGT-ar \
	RANLIB=$LFS_TGT-ranlib \
	../configure \
	--prefix=/tools \
	--with-local-prefix=/tools \
	--with-native-system-header-dir=/tools/include \
	--enable-languages=c,c++ \
	--disable-libstdcxx-pch \
	--disable-multilib \
	--disable-bootstrap \
	--disable-libgomp \
	&& make \
	&& make install
}
ln -sv gcc /tools/bin/cc


echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'
rm -v dummy.c a.out

popd
rm -rf gcc-6.3.0
