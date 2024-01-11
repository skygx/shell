#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   findsuid.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/25 上午 8:11         hello      1.0         None
INFO

mtime="7"
verbose=0

if [ "$1" = "-v" ]; then
    verbose=1
fi

#find / -type f -perm +4000 -print0 | while read -d '' -r match
find / -type f -perm /4000 -print0 | while read -d '' -r match
do
    if [ -x "$match" ]; then
        owner="$(ls -ld $match | awk '{print $3}')"
        perms="$(ls -ld $match | cut -c5-10 | grep 'w')"
        if [ ! -z $perms ]; then
            echo "**** $match (writeable and setuid $owner)"
        elif [ ! -z $(find $match -mtime -$mtime -print) ]; then
            echo "**** $match (modified within $mtime days and setuid $owner)"
        elif [ $verbose -eq 1 ]; then
            lastmod="$(ls -ld $match | awk '{print $6, $7, $8}')"
            echo "      $match (setuid $owner, last modified $lastmod)"
        fi
    fi
done

exit 0
