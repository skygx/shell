#/bin/sh
set -u
#�ù���yumԴ
local="/etc/yum.repos.d/local.repo"
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
cd /etc/yum.repos.d/
curl -O http://mirrors.aliyun.com/repo/Centos-7.repo

yum clean all
yum makecache

#����ʱ��
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# ����ʱ����ͬ��ʱ��
ntp_svr="cn.pool.ntp.org"
yum -y install utp ntpdate && ntpdate cn.pool.ntp.org && hwclock --systohc && timedatectl set-timezone Asia/Shanghai

# ����selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# �رշ���ǽ
if egrep "7.[0-9]" /etc/redhat-release &>/dev/null; then
    systemctl stop firewalld
    systemctl disable firewalld
elif egrep "6.[0-9]" /etc/redhat-release &>/dev/null; then
    service iptables stop
    chkconfig iptables off
fi

# ��ʷ������ʾ����ʱ��
if ! grep HISTTIMEFORMAT /etc/bashrc; then
    echo 'export HISTTIMEFORMAT="%F %T `whoami` "' >> /etc/bashrc
fi

# SSH��ʱʱ��
if ! grep "TMOUT=1800" /etc/profile &>/dev/null; then
    echo "export TMOUT=1800" >> /etc/profile
fi

# ��ֹrootԶ�̵�¼
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# ��ֹ��ʱ���������ʼ�
sed -i 's/^MAILTO=root/MAILTO=""/' /etc/crontab 

# ���������ļ���
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
EOF

# ϵͳ�ں��Ż�
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 20480
net.ipv4.tcp_max_syn_backlog = 20480
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_fin_timeout = 20  
EOF

# ����SWAPʹ��
echo "0" > /proc/sys/vm/swappiness

# ��װϵͳ���ܷ������߼�����
yum install gcc make autoconf vim sysstat wget unzip  net-tools iostat iftop iotp lrzsz bash-completion wget dos2unix -y

# ˢ�»�������
source ~/.bashrc