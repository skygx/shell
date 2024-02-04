#!/bin/bash
# **********************************************************
# * Author        : xguo
# * Create time   : 2023-11
# * Filename      : check_user.sh
# **********************************************************
#set -x
export PS4='+${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]}  '
LANG=en_US.utf-8

login=()
nologin=()
super=()
while read line
do
    user_id=`echo "${line}"|awk -F':' '{print $3}'`
    username=`echo "${line}"|awk -F':' '{print $1}'`    
    if [ "${user_id}" == "0" ];then
    super+=("${username}")
    fi

    if [ "${user_id}" -ge "1000" ] && [ "${user_id}" -lt "2000" ];then
        rights=`echo "${line}"|grep "${username}"|awk -F'/sbin/|/bin/' '{print $2}'`
        if [ "${rights}" == "nologin" ];then
        nologin+=("${username}")
        elif [ "${rights}" == "bash" ];then
        login+=("${username}")
        fi
    fi
done < /etc/passwd
echo -e "\033[32m当前可登录系统的普通用户为:${login[@]}\033[0m"
echo -e "\033[31m不具备登录权限的用户为:${nologin[@]}\033[0m"
echo -e "\033[35m当前系统内的超级管理员为:${super[@]}\033[0m"
