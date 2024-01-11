#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   checkexternal.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/26 上午 8:42         hello      1.0         None
INFO

listall=0;  errors=0;   checked=0

if [ "$1" = "-a" ]; then
    listall=1; shift
fi

if [ -z "$1" ]; then
    echo "Usage: $(basename $0) [-a] URL" >&2
    exit 1
fi

trap "$(which rm) -f traverse*.errors reject*.dat traverse*.dat" 0

outfile="$(echo "$1" | cut -d/ -f3).errors.ext"
URLlist="$(echo $1|cut -d/ -f3|sed 's/www\.//').rejects"

rm -f $outfile

if [ ! -e "$URLlist" ]; then
    echo "File $URLlist not found. Please run checklinks first. " >&2
    exit 1
fi

if [ ! -s "$URLlist" ]; then
    echo "There don't appear to be any external links ($URLlist is empty). " >&2
    exit 1
fi

for URL in $(cat $URLlist | sort | uniq)
do
    curl -s "$URL" > /dev/null 2>&1; return=$?
    if [ $return -eq 0 ]; then
        if [ $listall -eq 1 ]; then
            echo "$URL is fine."
        fi
    else
        echo "$URL fails with error code $return"
        errors=$(( $errors + 1 ))
    fi
    checked=$(( $checked + 1 ))
done

echo ""
echo "Done. Checked $checked URLs and found $errors errors."
exit 0
