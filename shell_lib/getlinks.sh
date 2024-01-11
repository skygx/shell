#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   getlinks.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo
    @example :   getlinks.sh -a http://www.amazon.com/
@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/25 上午 11:17         hello      1.0         None
INFO

if [ $# -eq 0 ]; then
    echo "Usage: $0 [-d|-i|-x] url" >&2
    echo "-d=domains only, -i=internal refs only, -x=external only" >&2
    exit 1
fi

if [ $# -gt 1 ]; then
    case "$1" in
    -d) lastcmd="cut -d/ -f3 | sort | uniq"
        shift
       ;;
    -r) basedomain="http://$(echo $2 | cut -d/ -f3)/"
        lastcmd="grep \"^$basedomain\" |sed \"s|$basedomain||g\" | sort | uniq"
        shift
        ;;
    -a) basedomain="http://$(echo $2 | cut -d/ -f3)/"
        lastcmd="grep -v \"^$basedomain\" | sort | uniq"
        shift
        ;;
    *)  echo "$0: unknown option specified: $1" >&2
        exit 1
    esac
else
    lastcmd="sort|uniq"
fi

lynx -dump "$1" | \
    sed -n '/^References$/,$p' | \
    grep -E '[[:digit:]]+\.' | \
    awk '{print $2}' | \
    cut -d\? -f1 | \
    eval $lastcmd
exit 0
