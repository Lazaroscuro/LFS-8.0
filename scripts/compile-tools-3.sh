#!/bin/bash
export MAKEFLAGS='-j 8'
cd $LFS/sources

# Tcl-core
tar -xf tcl-core8.6.6-src.tar.gz
pushd tcl-core8.6.6-src

cd unix
time {
	./configure --prefix=/tools
	make && make install \
	&& chmod -v u+w /tools/lib/libtcl8.6.so \
	&& make install-private-headers \
	ln -sv tclsh8.6 /tools/bin/tclsh
}

popd
rm -rf tcl-core8.6.6-src

# Expect

tar -xf expect5.45.tar.gz
pushd expect5.45

cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure

time {
	./configure --prefix=/tools \
	--with-tcl=/tools/lib \
	--with-tclinclude=/tools/include \
	&& make && make SCRIPTS="" install
}

popd
rm -rf expect5.45

# DejaGNU
tar -xf dejagnu-1.6.tar.gz
pushd dejagnu-1.6

time {
	./configure --prefix=/tools \
	&& make install
}

popd
rm -rf dejagnu-1.6

# Check

tar -xf check-0.11.0.tar.gz
pushd check-0.11.0

time {
	PKG_CONFIG= ./configure --prefix=/tools \
	&& make && make install
}

popd
rm -rf check-0.11.0

# Ncurses
tar -xf ncurses-6.0.tar.gz
pushd ncurses-6.0

sed -i s/mawk// configure
time {
	./configure --prefix=/tools \
	--with-shared \
	--without-debug \
	--without-ada \
	--enable-widec \
	--enable-overwrite \
	&& make \
	&& make install
}

popd
rm -rf ncurses-6.0.tar.gz

# Bash
tar -xf bash-4.4.tar.gz
pushd bash-4.4

time {
	./configure --prefix=/tools --without-bash-malloc \
	&& make \
	&& make install \
	&& ln -sv bash /tools/bin/sh
}

popd
rm -rf bash-4.4

# Bison
tar -xf bison-3.0.4.tar.xz
pushd bison-3.0.4

time {
	./configure --prefix=/tools \
	&& make \
	&& make install
}

popd
rm -rf bison-3.0.4

# Bzip2
tar -xf bzip2-1.0.6.tar.gz
pushd bzip2-1.0.6

time {
	make \
	&& make PREFIX=/tools install
}

popd
rm -rf bzip2-1.0.6

# Coreutils
tar -xf coreutils-8.26.tar.xz
pushd coreutils-8.26

time {
	./configure --prefix=/tools --enable-install-program=hostname \
	&& make \
	&& make install
}

popd
rm -rf coreutils-8.26
