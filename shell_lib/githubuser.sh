#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   githubuser.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/25 下午 12:53         hello      1.0         None
INFO

if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

curl -s "https://api.github.com/users/$1" | \
    awk -F'"' '
        /\"name\":/ {
            print $4" is the name of the Github user."
        }
        /\"followers\":/ {
            split($3,a," ")
            sub(/,/, "",a[2])
            print "They have "a[2]" followers."
        }
        /\"following\":/ {
            split($3,a," ")
            sub(/,/, "",a[2])
            print "They are following "a[2]" other users."
        }
        /\"created_at\":/ {
            print "Their account was created on "$4"."
        }

    '
exit 0
