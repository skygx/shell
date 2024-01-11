#!/bin/bash
PKG_DIR="/usr/local/src"
PKG="ipvsadm-1.26.tar.gz"

yum -y install gcc gcc-c++ kernel-devel libnl* libpopt* popt-static
lsmod | grep ip_vs
[ -d $PKG_DIR ] || mkdir -p $PKG_DIR
cd $PKG_DIR
wget http://www.linuxvirtualserver.org/software/kernel-2.6/$PKG
tar -xvf $PKG
ln -s /usr/src/kernels/2.6.32-696.1.1.el6.x86_64/ /usr/src/linux
make && make install
ipvsadm
lsmod | grep ip_vs
