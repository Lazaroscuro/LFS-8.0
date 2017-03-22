#!/bin/bash
export MAKEFLAGS='-j 8'
cd $LFS/sources

# Binutils
tar -xf binutils-2.27.tar.bz2
pushd binutils-2.27

mkdir -v build && cd build
time {
	../configure --prefix=/tools \
	--with-sysroot=$LFS \
	--with-lib-path=/tools/lib \
	--target=$LFS_TGT \
	--disable-nls \
	--disable-werror \
	&& make \
	&& case $(uname -m) in
		x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
	esac \
	&& make install
}
popd
rm -rf binutils-2.27

# GCC
tar -xf gcc-6.3.0.tar.bz2
pushd gcc-6.3.0

tar -xf ../mpfr-3.1.5.tar.xz
mv -v mpfr-3.1.5 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.0.3.tar.gz
mv -v mpc-1.0.3 mpc

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

mkdir -v build && cd build
time {
	../configure \
	--target=$LFS_TGT \
	--prefix=/tools \
	--with-glibc-version=2.11 \
	--with-sysroot=$LFS \
	--with-newlib \
	--without-headers \
	--with-local-prefix=/tools \
	--with-native-system-header-dir=/tools/include \
	--disable-nls \
	--disable-shared \
	--disable-multilib \
	--disable-decimal-float \
	--disable-threads \
	--disable-libatomic \
	--disable-libgomp \
	--disable-libmpx \
	--disable-libquadmath \
	--disable-libssp \
	--disable-libvtv \
	--disable-libstdcxx \
	--enable-languages=c,c++ \
	&& make \
	&& make install
}
popd
rm -rf gcc-6.3.0

# Linux API Headers
tar -xf linux-4.9.9.tar.xz
pushd linux-4.9.9

time {
	make mrproper \
	&& make INSTALL_HDR_PATH=dest headers_install
}
cp -rv dest/include/* /tools/include
 
popd
rm -rf linux-4.9.9

# Glibc
tar -xf glibc-2.25.tar.xz
pushd glibc-2.25

mkdir -v build && cd build
time {
	../configure \
	--prefix=/tools \
	--host=$LFS_TGT \
	--build=$(../scripts/config.guess) \
	--enable-kernel=2.6.32 \
	--with-headers=/tools/include \
	libc_cv_forced_unwind=yes \
	libc_cv_c_cleanup=yes \
	&& make \
	&& make install
}

echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'
rm -v dummy.c a.out

popd
rm -rf glibc-2.25
