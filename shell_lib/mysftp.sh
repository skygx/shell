#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   mysftp.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 下午 3:32         hello      1.0         None
INFO

. ./library.sh

echon "User account: "
read account

if [ -z $account ]; then
    exit 0;
fi

if [ -z "$1" ]; then
    echon "Remote host: "
    read host
    if [ -z $hosts ]; then
        exit 0
    fi
else
    host=$1
fi

exec sftp -C $account@$host
