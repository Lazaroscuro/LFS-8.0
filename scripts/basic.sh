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

mkdir -pv $LFS/{dev,proc,sys,run} \
&& mknod -m 600 $LFS/dev/console c 5 1 \
&& mknod -m 666 $LFS/dev/null c 1 3 \
&& mount -v --bind /dev $LFS/dev \
&& mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620 \
&& mount -vt proc proc $LFS/proc \
&& mount -vt sysfs sysfs $LFS/sys \
&& mount -vt tmpfs tmpfs $LFS/run

RET=$?
if [ $RET -ne 0 ]; then
	echo ERROR: dev mount failure
	exit $RET
fi

if [ -h $LFS/dev/shm ]; then
	mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

chroot "$LFS" /tools/bin/env -i \
	HOME=/root \
	TERM="$TERM" \
	PS1='\u:\w\$ ' \
	PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
	/tools/bin/bash --login +h

mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -v /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v /usr/libexec
mkdir -pv /usr/{,local/}share/man/man{1..8}

case $(uname -m) in
	x86_64) mkdir -v /lib64 ;;
esac

mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}

ln -sv /tools/bin/{bash,cat,echo,pwd,stty} /bin
ln -sv /tools/bin/perl /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
ln -sv bash /bin/sh

# Mandatory compatibility (now /proc is the way to go)
ln -sv /proc/self/mounts /etc/mtab

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
nogroup:x:99:
users:x:999:
EOF

exec /tools/bin/bash --login +h
echo NEW SHELL!!!
sleep 5
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664 /var/log/lastlog
chmod -v 600 /var/log/btmp

cd /sources

# Linux API Headers
tar -xf linux-4.9.9.tar.xz
pushd linux-4.9.9

time {
	make mrproper \
	&& make INSTALL_HDR_PATH=dest headers_install \
	&& find dest/include \( -name .install -o -name ..install.cmd \) -delete \
	&& cp -rv dest/include/* /usr/include
}
 
popd
rm -rf linux-4.9.9

# Man-pages
tar -xf man-pages-4.09.tar.xz
pushd man-pages-4.09

time {
	make install
}

popd
rm -rf man-pages-4.09

# Glibc
tar -xf glibc-2.25.tar.xz
pushd glibc-2.25

time {
	patch -Np1 -i ../glibc-2.25-fhs-1.patch
	case $(uname -m) in
		x86) ln -s ld-linux.so.2 /lib/ld-lsb.so.3
		;;
		x86_64) ln -s ../lib/ld-linux-x86-64.so.2 /lib64
			ln -s ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
		;;
	esac
	mkdir -v build \
	&& cd build \
	&& ../configure --prefix=/usr \
		--enable-kernel=2.6.32 \
		--enable-obsolete-rpc \
		--enable-stack-protector=strong \
		libc_cv_slibdir=/lib \
	&& make \
	&& make check
	touch /etc/ld.so.conf
	make install \
	&& cp -v ../nscd/nscd.conf /etc/nscd.conf \
	&& mkdir -pv /var/cache/nscd

	make -pv /usr/lib/locale
	localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
	localedef -i de_DE -f ISO-8859-1 de_DE
	localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
	localedef -i de_DE -f UTF-8 de_DE.UTF-8
	localedef -i en_GB -f UTF-8 en_GB.UTF-8
	localedef -i en_HK -f ISO-8859-1 en_HK
	localedef -i en_PH -f ISO-8859-1 en_PH
	localedef -i en_US -f ISO-8859-1 en_US
	localedef -i en_US -f UTF-8 en_US.UTF-8
	localedef -i es_MX -f ISO-8859-1 es_MX
	localedef -i fa_IR -f UTF-8 fa_IR
	localedef -i fr_FR -f ISO-8859-1 fr_FR
	localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
	localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
	localedef -i it_IT -f ISO-8859-1 it_IT
	localedef -i it_IT -f UTF-8 it_IT.UTF-8
	localedef -i ja_JP -f EUC-JP ja_JP
	localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
	localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
	localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
	localedef -i zh_CN -f GB18030 zh_CN.GB18030
}

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2016j.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica \
		asia australasia backward pacificnew systemv; do
	zic -L /dev/null -d $ZONEINFO -y "sh yearistype.sh" ${tz}
	zic -L /dev/null -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
	zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
cp -v /usr/share/zoneinfo/America/New_York /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g' \
	-e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
	-e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' > \
	`dirname $(gcc --print-libgcc-file-name)`/specs

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
grep -B1 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
echo References to paths that have components with '-linux-gnu' should be ignored, but otherwise the output of the last
command should be SEARCH_DIR root usr lib and root lib

grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v dummy.c a.out dummy.log

popd
rm -rf glibc-2.25

sh lfs-umount.sh
RET=$?
if [ $RET -ne 0 ]; then
	echo ERROR: unmount \(you must create lfs-mount.sh and lfs-unmount.sh\)
	exit $RET
fi

echo done!
