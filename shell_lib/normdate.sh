#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   normdate.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 上午 9:30         hello      1.0         None
INFO

monthNumToName()
{
case $1 in
1)  month="Jan"   ;;    2)  month="Feb";;
3)  month="Mar"   ;;    4)  month="Apr";;
5)  month="May"   ;;    6)  month="Jun";;
7)  month="Jul"   ;;    8)  month="Aug";;
9)  month="Sep"   ;;    10)  month="Oct";;
11)  month="Nov"   ;;    12)  month="Dec";;
*)  echo "$0: Unknown numeric month value $1" >&2
    exit 1
esac
return 0
}
if [ $# -eq 1 ]; then
    set -- $(echo $1 |sed 's/[\/\-]/ /g')
fi

if [ $# -ne 3 ]; then
    echo "Usage: $0 month day year" >&2
    echo "Formats are August 3 1962 and 8 3 1962" >&2
    exit 1
fi

if [ $3 -le 99 ]; then
    echo "$0: expected 4-digit year value." >&2
    exit 1
fi

if [ -z $(echo $1|sed 's/[[:digit:]]//g') ]; then
    monthNumToName $1
else
month="$(echo $1|cut -c1|tr '[:lower:]' '[:upper:]')"
month="$month$(echo $1|cut -c2-3|tr '[:upper:]' '[:lower:]')"
fi

echo $month $2 $3
exit 0
