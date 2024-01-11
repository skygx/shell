
#!/bin/bash

if [ $USER != "root" ]; then
    echo "please use root privileges to run script."
    exit 1
fi

HOSTNAME=node1
# Update the system
yum update -y

# Install necessary packages
yum install -y vim wget curl net-tools gcc gcc-c++ vim-enhanced unzip unrar sysstat ntp
echo "01 01 * * * /usr/sbin/ntpdate ntp.api.bz >> /dev/null 2>&1" >> /etc/crontab
ntpdate ntp.api.bz

ulimit -SHn 65535
echo "ulimit -SHn 65535" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
*      soft    nofile    65535
*      hard    nofile    65535
EOF

cat >> /etc/sysctl.conf << EOF
fs.file-max=419430
net.ipv4.ip_forward = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_rmem = 4096 4096 16777216
net.ipv4.tcp_wmem = 4096 4096 16777216
net.ipv4.tcp_mem = 786432 2097152 3145728
net.ipv4.tcp_max_orphans = 131072
kernel.shmmax = 134217728
EOF
/sbin/sysctl -p

# Set hostname
hostnamectl set-hostname ${HOSTNAME}

# Disable SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Disable firewall
systemctl stop firewalld
systemctl disable firewalld

# Enable password authentication
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's@#PermitRootLogin yes@PermitRootLogin no@' /etc/ssh/sshd_config
sed -i 's@#PermitEmptyPasswords no@PermitRootLogin no@' /etc/ssh/sshd_config
sed -i 's@#UseDNS yes@UseDNS no@' /etc/ssh/sshd_config
systemctl restart sshd

echo "alias net-pf-10 off" >> /etc/modprobe.d/dist.conf
echo "alias ipv6 off" >> /etc/modprobe.d/dist.conf
echo "IPV6INIT=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0

chkconfig ip6tables off
chkconfig iptables off

cat >> /root/.vimrc << EOF
set number
set ruler
set nohlsearch
set shiftwidth=2
set tabstop=4
set expandtab
set cindent
set autoindent
set mouse=v
syntax on
EOF

for i in $(chkconfig --list|grep 3:on|awk '{print $1}')
do
    chkconfig --level 3 $i off
done

for CURSRV in crond sshd rsyslog network
do
    chkconfig --level 3 $CURSRV on
done