#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   log-baidu-search.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo
    @Example :   http://192.168.226.30/cgi-bin/log-baidu-search.cgi?q=metasploit

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/25 下午 4:42         hello      1.0         None
INFO

logfile="/var/www/log/searchlog.txt"

if [ ! -f $logfile ]; then
    touch $logfile
    chmod a+rw $logfile
fi

if [ -w $logfile ]; then
    echo "$(date): $QUERY_STRING" | sed 's/wd=//g;s/+/ /g'  >> $logfile
fi

echo "Location: https://www.baidu.com/s?$QUERY_STRING"
echo ""
exit 0
