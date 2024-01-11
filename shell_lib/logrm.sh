#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   logrm.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 上午 10:34         hello      1.0         None
INFO

removelog="/tmp/remove.log"

if [ $# -eq 0 ]; then
    echo "Usage: $0 [-s] list of files or directories" >&2
    exit 1
fi

if [ "$1" = "-s" ]; then
    shift
else
#    echo "$(date): ${USER}: $@" >> $removelog
    logger -t logrm "${USER:-LOGNAME}: $*"
fi
/bin/rm -R "$@"
exit 0
