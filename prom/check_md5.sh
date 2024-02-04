#!/bin/bash
# **********************************************************
# * Author        : xguo
# * Create time   : 2023-11
# * Filename      : check_md5.sh
# **********************************************************
#set -x

function random_color(){
    color_ansi=$((RANDOM % 256))
    echo -e "\033[38;5;${color_ansi}m${1}\033[0m"
}

src="/root/test/*"
dst="/tmp/test/"
for dir in ${src}
do
    filename=$(basename $dir)
    [ -d "${src%/*}/${filename}" ] && continue
    dest=${dst}${filename}
    S=$(md5sum ${dir}|awk '{print $1}')
    D=$(md5sum ${dest}|awk '{print $1}')
    if [ "${S}" == "${D}" ];then
          true
	  random_color "检测到 ${dir} 文件未被修改"
    else
          random_color "检测到 ${dir} 文件被修改过"
    fi
done
