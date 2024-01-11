#！/bin/bash

yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel gcc perl-ExtUtils-MakeMaker
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.31.1.tar.gz  
tar -xf git-2.31.1.tar.gz  
cd git-2.31.1
make prefix=/usr/local/git all
make prefix=/usr/local/git install

echo "export PATH=$PATH:/usr/local/git/bin" >> /etc/profile
source /etc/profile
