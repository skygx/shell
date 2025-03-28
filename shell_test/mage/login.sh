#!/bin/bash

lastb | sed -rn '/ssh:/ s@.* (([0-9]{2,5}.){3}[0-9]{1,3}).*@\1@p'|sort |uniq -c| while read count ip ;do 
 if [ $count -ge 1 ];then
 #iptables -A INPUT -s $ip -j REJECT
 echo $count  $ip
 fi
done
