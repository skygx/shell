#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   docron.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/25 上午 9:40         hello      1.0         None
INFO

rootcron="/etc/crontab"

if [ $# -ne 1 ]; then
    echo "Usage: $0 [daily|weekly|monthly]" >&2
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "$0: Command must be run as 'root'" >&2
    exit 1
fi

job="$(awk "NF > 6 && /$1/ {for (i=7;i<=NF;i++) print \$i }" $rootcron)"

if [ -z "$job" ]; then
    echo "$0: Error: no $1 job found in $rootcron" >&2
    exit 1
fi

SHELL=$(which sh)

eval $job
