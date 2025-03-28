#!/bin/sh
#example: sh ftp_put.sh 172.16.19.164 hello xin ./ftp_get.sh /ftp_get.sh
if [ $# -lt 5 ];then
    echo -e "\033[31m Usage:./ftp_get.sh ip user password file \033[0m"
    exit 1
fi
ip=$1
user=$2
password=$3
local_path=$4
remote_path=$5

#passive

ftp -v -n $ip <<EOF
user $user $password
binary
put $local_path $remote_path
bye
EOF

