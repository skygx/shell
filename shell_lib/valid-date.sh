#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   valid-date.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 上午 9:52         hello      1.0         None
INFO

. ./library.sh

if [ $# -ne 3 ]; then
    echo "Usage: $0 month day year" >&2
    echo "Typical input formats are August 3 1962 and 8 3 1962" >&2
    exit 1
fi

newdate="$(normdate.sh "$@")"
if [ $? -eq 1 ]; then
exit 1
fi

month="$(echo $newdate | cut -d\  -f1)"
day="$(echo $newdate | cut -d\  -f2)"
year="$(echo $newdate | cut -d\  -f3)"

if ! exceedsDaysInMonth $month "$2" ; then
if [ "$month" = "Feb" -a "$2" -eq "29" ]; then
if ! isLeapYear $3; then
    echo "$0: $3 is not a leap year, so Feb doesn't have 29 days." >&2
    exit 1
fi
else
    echo "$0: bad day value: $month doesn't have $2 days." >&2
    exit 1
fi
fi

echo "Valid date: $newdate"
exit 0
