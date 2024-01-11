#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   exec_cmd.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 上午 10:18         hello      1.0         None
INFO

IFS=":"
count=0; nonex=0
for directory in $PATH; do
    if [ -d "$directory" ]; then
        for command in "$directory"/*; do
            if [ -x "$command" ]; then
                count="$(( $count + 1 ))"
            else
                nonex="$(( $nonex + 1 ))"
            fi
        done
    fi
done

echo "$count commands, and $nonex entries that weren't executable"
exit 0
