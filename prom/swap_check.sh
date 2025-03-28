#!/bin/bash

echo -e "pid\tswap\tproc_name"
for pid in $(ls -l /proc | grep ^d | awk '{ print $9 }'| grep  -v [^0-9]); do
    # 判断改进程是否占用了swap
    grep -q "Swap" /proc/$pid/smaps 2>/dev/null
    if [ $? -eq 0 ];then
    # 如果占用了swap
        swap=$(grep Swap /proc/$pid/smaps | gawk '{ sum+=$2;} END { print sum }')
        proc_name=$(ps aux | grep -w "$pid" | grep -v grep  | awk '{ for(i=11;i<=NF;i++){ printf("%s ",$i); }}')
        if [ $swap -gt 0 ];then
        # 输出swap信息
            echo -e "$pid\t${swap} KB\t$proc_name"
        fi
    fi
    done | sort -k2 -rn |head -n 10
