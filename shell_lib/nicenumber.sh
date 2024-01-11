#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   nicenumber.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 上午 9:45         hello      1.0         None
INFO

. ./library.sh
DD="."
TD=","

while getopts "d:t:" opt;do
    case $opt in
    d)  DD="$OPTARG"    ;;
    t)  TD="$OPTARG"    ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -eq 0 ] ; then
    echo "Usage: $(basename $0) [-d c] [-t c] numeric_value"
    echo "  -d specifies the decimal point delimiter (default '.')"
    echo "  -t specifies the decimal point delimiter (default ',')"
    exit 0
fi
nicenumber $1 1
exit 0
