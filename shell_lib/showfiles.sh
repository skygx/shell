#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   showfiles.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 下午 3:19         hello      1.0         None
INFO

width=72
for input
do
    echo $input
    lines="$(wc -l < $input | sed 's/ //g')"
    chars="$(wc -c < $input | sed 's/ //g')"
    owner="$(ls -ld $input |awk '{print $3}')"
    echo "------------------------------------------------------------------"
    echo "File $input ($lines lines, $chars characters, owned by $owner):"
    echo "------------------------------------------------------------------"
    while read line
    do
        if [ ${#line} -gt $width ]; then
            echo "$line" | fmt | sed -e '1s/^/  /' -e '2,$s/^/+ /'
        else
            echo "  $line"
        fi
    done < $input
    echo "------------------------------------------------------------------"
#done | ${PAGER:more}
done | more

exit 0
