#!/usr/bin/env bash
# Create Date: 2022/2/15 下午 12:02
# Author:      hello
# Mail:        guoxin_well@126.com
# Version:     1.0
# Attention:   interface_flow.sh
set -eu

eth0=$1
echo  -e    "流量进入--流量传出    "
while true; do
 old_in=$(cat /proc/net/dev |grep $eth0 |awk '{print $2}')
 old_out=$(cat /proc/net/dev |grep $eth0 |awk '{print $10}')
 sleep 1
 new_in=$(cat /proc/net/dev |grep $eth0 |awk '{print $2}')
 new_out=$(cat /proc/net/dev |grep $eth0 |awk '{print $10}')
 in=$(printf "%.1f%s" "$((($new_in-$old_in)/1024))" "KB/s")
 out=$(printf "%.1f%s" "$((($new_out-$old_out)/1024))" "KB/s")
 echo "$in $out"
done
