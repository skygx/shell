#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   setdate.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/25 上午 8:29         hello      1.0         None
INFO

. ./library.sh

askvalue()
{
    echon "$1 [$2] : "
    read answer
    if [ ${answer:=$2} -gt $3 ]; then
        echo "$0: $1 $answer is invalid"
        exit 0
    elif [ "$(( $(echo $answer | wc -c) - 1 ))" -lt $4 ]; then
        echo "$0: $1 $answer is too short: please specify $4 digits"
        exit 0
    fi
    eval $1=$answer
}

eval $(date "+nyear=%Y nmon=%m nday=%d nhr=%H nmin=%M")

askvalue year $nyear 3000 4
askvalue month $nmon 12 2
askvalue day $nday 31 2
askvalue hour $nhr 24 2
askvalue minute $nmin 59 2

#squished="$year$month$day$hour$minute"
squished="$month$day$hour$minute$year"

echo "Setting date to $squished. You might need to enter your sudo password: "
sudo date $squished

exit 0
