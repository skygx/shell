#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   webaccess.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/26 上午 9:03         hello      1.0         None
INFO
. ./library.sh

bytes_in_gb=1048576

host="node1"

if [ $# -eq 0 ]; then
    echo "Usage: $(basename $0) logfile" >&2
    exit 1
fi

if [ ! -r $1 ]; then
    echo "Error: log file $1 not found." >&2
    exit 1
fi

firstdate="$(head -1 $1 | awk '{print $4}' | sed 's/\[//')"
lastdate="$(tail -1 $1 | awk '{print $4}' | sed 's/\[//')"

echo "Results of analyzing log file $1"
echo ""
echo "  Start date : $(echo $firstdate|sed 's/:/ at /')"
echo "    End date : $(echo $lastdate|sed 's/:/ at /')"

hits="$(wc -l < "$1" |sed 's/[^[:digit:]]//g')"
echo "    Hits: $(nicenumber.sh $hits) (total accesses)"
pages="$(grep -ivE '(.gif|.jpg|.png)' "$1" | wc -l | sed 's/[^[:digit:]]//g')"
echo "    Pageviews: $(nicenumber.sh $pages) (hits minus graphics)"

totalbytes="$(awk '{sum+=$10} END {print sum}' "$1")"
echon "  Transferred: $(nicenumber.sh $totalbytes) bytes "

if [ $totalbytes -gt $bytes_in_gb ]; then
    echo "($(scriptbc $totalbytes / $bytes_in_gb) GB)"
elif [ $totalbytes -gt 1024 ]; then
    echo "($(scriptbc $totalbytes / 1024) MB)"
else
    echo ""
fi

echo ""
echo "The ten most popular pages were: "
awk '{print $7}' "$1" | grep -ivE '(.gif|.jpg|.png)' | \
    sed 's/\/$//g' | sort | \
    uniq -c | sort -rn | head -10
echo ""
echo "The ten most common referrer URLs were: "
awk '{print $11}' "$1" | \
    grep -vE "(^\"-\"$|/www.$host|/$host)" | \
    sort | uniq -c | sort -nr | head -10

echo ""
exit 0
