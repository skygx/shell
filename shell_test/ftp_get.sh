#!/bin/sh
# example: ./ftp_get.sh 172.16.19.164 hello xin shell.20231018-162336.log
if [ $# -lt 4 ];then
    echo -e "\033[31m Usage:./ftp_get.sh ip user password file \033[0m"
    exit 1
fi

ip=$1
user=$2
pass=$3
remote_file=$4
#local_path=$5
#passive

ftp -v -n $ip <<EOF
user $user $pass
binary
get $remote_file
bye
EOF

#if [ $? -eq 0 ];then
#	echo -e "\033[32m ftp file download successfule.\033[0m"
#else
#	echo -e "\033[31m ftp file download failed!!\033[0m"
#fi
