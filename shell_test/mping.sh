#!/bin/bash
#定义一个函数，ping 某一台主机，并检测主机的存活状态

myping(){
ping -c2 -i0.3 -W1 $1 &>/dev/null
if [ $? -eq 0 ];then
echo "$1 is up"
else
echo "$1 is down"
fi
}
for i in {1..254}
do
 myping 192.168.226.$i &
done
