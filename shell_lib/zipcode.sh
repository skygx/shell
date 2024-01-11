#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   zipcode.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/25 下午 1:00         hello      1.0         None
INFO

baseURL="http://www.city-data.com/zips"

echo -n "ZIP code $1 is in "

curl -s -dump "$baseURL/$1.html" | \
grep -i '<title>' | \
cut -d\( -f2 | cut -d \) -f1

exit 0
