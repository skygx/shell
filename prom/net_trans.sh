#!/bin/bash
while :
do
 echo '本地网卡 eth0 流量信息如下: '
 ifconfig ens33| grep "RX pack" | awk '{print "RX: "$5}'
 ifconfig ens33| grep "TX pack" | awk '{print "TX: "$5}'
 sleep 1
done
