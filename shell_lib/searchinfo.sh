#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   searchinfo.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/26 上午 9:53         hello      1.0         None
INFO

host="node1"
maxmatched=20
count=0
temp="/tmp/$(basename $0).$$"

#trap "$(which rm) -f $temp" 0

if [ $# -eq 0 ]; then
    echo "Usage: $(basename $0) logfile" >&2
    exit 1
fi

if [ ! -r "$1" ]; then
    echo "Error: can't open file $1 for analysis. " >&2
    exit 1
fi

for URL in $(awk '{ if (length($11) > 4) {print $7}}' "$1" | \
    grep -vE "(/www.$host|/$host)" | grep '?')
do
#    searchengine="$(echo $URL | cut -d/ -f3 | rev | cut -d. -f1-2 | rev)"
    searchengine="$(echo $URL | cut -d/ -f3 | rev | cut -d. -f2 | rev)"
    args="$(echo $URL | cut -d\? -f2 | tr '&' '\n' | \
        grep -E '(^q=|^sid=|^p=|query=|item=|ask=|name=|topic=|wd=)' | \
        sed -e 's/+/ /g' -e 's/%20/ /' -e 's/"//g' | cut -d= -f2)"
    if [ ! -z "$args" ]; then
        echo "${searchengine}:    $args" >> $temp
    else
        echo "${searchengine}    $(echo $URL | cut -d\? -f2)" >> $temp
    fi
    count="$(( $count + 1 ))"
done

echo "Search engine referrer info extracted from ${1}:"
sort $temp | uniq -c | sort -rn | head -$maxmatched | sed 's/^/ /g'
echo ""
echo Scanned $count entries in log file out of $(wc -l < "$1") total.
exit 0
