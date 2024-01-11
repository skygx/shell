#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   cgrep.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 下午 4:45         hello      1.0         None
INFO
. ./library.sh

context=0
#esc="^["
#boldon="${esc}[1m"  boldoff="${esc}[22m"
sedscript="/tmp/cgrep.sed.$$"
tempout="/tmp/cgrep.$$"

function showMatches
{
matches=0
echo "s/$pattern/${redf}${boldon}$pattern${boldoff}${reset}/g" > $sedscript
for lineno in $(grep -n "$pattern" $1 | cut -d: -f1)
do
    if [ $context -gt 0 ]; then
        prev="$(( $lineno - $context ))"
        if [ $prev -lt 1 ]; then
            prev="1"
        fi
        next="$(( $lineno + $context ))"
        if [ $matches -gt 0 ]; then
            echo "${prev}i\\" >> $sedscript
            echo "----" >> $sedscript
        fi
        echo "${prev},${next}p" >> $sedscript
    else
        echo "${lineno}p" >> $sedscript
    fi
    matches="$(( $matches + 1 ))"
done
if [ $matches -gt 0 ]; then
    sed -n -f $sedscript $1 | uniq | more
fi
}

trap "$(which rm) -f $tempout $sedscript" EXIT

if [ -z "$1" ]; then
    echo "Usage: $0 [-c X] pattern {filename}" >&2
    exit 0
fi

if [ "$1" = "-c" ] ; then
    context="$2"
    shift; shift
elif [ "$(echo $1|cut -c1-2)" = "-c" ] ; then
    context="$(echo $1|cut -c3-)"
    shift
fi

pattern="$1"; shift
if [ $# -gt 0 ]; then
    for filename ; do
        echo "----- $filename -----"
        showMatches $filename
    done
else
    cat - > $tempout
    showMatches $tempout
fi

exit 0
