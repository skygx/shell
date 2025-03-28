#!/usr/bin/env bash
# Create Date: 2022/2/15 下午 12:00
# Author:      hello
# Mail:        guoxin_well@126.com
# Version:     1.0
# Attention:   cpu_top.sh
set -eu

echo "-------------------CUP占用前10排序--------------------------------"
ps -eo user,pid,pcpu,pmem,args --sort=-pcpu  |head -n 10
echo "-------------------内存占用前10排序--------------------------------"
ps -eo user,pid,pcpu,pmem,args --sort=-pmem  |head -n 10
