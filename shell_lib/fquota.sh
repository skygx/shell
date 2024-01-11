#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   fquota.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 下午 3:43         hello      1.0         None
INFO

. ./library.sh

MAXDISKUSAGE=2000

for name in $(cut -d: -f1,3 /etc/passwd | awk -F: '$2 > 99 {print $1}')
do
    echon "User $name exceeds disk quota. Disk usage is: "
    find / /usr /var /home -xdev -user $name -type f -ls | \
    awk '{ sum += $7 }END{print sum / (1024*1024) "Mbytes"}'
done | awk "\$9 > $MAXDISKUSAGE {print \$0}"
exit 0
