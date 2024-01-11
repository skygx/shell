#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   validalnum.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2020-2021, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 上午 9:24         hello      1.0         None
INFO

validAlphaNum()
{
    validchars="$(echo $1 | sed -e 's/[^[:alnum:]]//g')"

    if [ "$validchars" = "$1" ] ; then
    return 0
    else
    return 1
    fi

}

echo -n "Enter input: "
read input
if ! validAlphaNum "$input" ; then
    echo "You input must consist of only letters and numbers." >&2
    exit 1
else
    echo "Input is valid."
fi
exit 0
