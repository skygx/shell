#!/bin/bash
for i in `seq 31 50`
do
cp /qemu/win7-templete.xml /qemu/win7-10.$i.xml       #复制模版配置
uuid=`uuidgen`             #随机uuid                   
mac1=`openssl rand -base64 8 | md5sum | cut -c1-2`            #随机两位mac
mac2=`openssl rand -base64 8 | md5sum | cut -c1-2`
sed -i "10c <uuid>$uuid</uuid>" win7-10.$i.xml                  #替换第十行的UUID
#修改配置中虚拟磁盘名称
sed -i "s/win7_templete.qcow2/win7_10.$i.qcow2/"  /qemu/win7-10.$i.xml  
#修改虚拟机名
sed -i "s/win7-templete/win7-10.$i/"  /qemu/win7-10.$i.xml
#修改第66行的mac地址
sed -i "66c  <mac address='52:54:00:f6:$mac1:$mac2'/>" win7-10.$i.xml
virsh define /qemu/win7-10.$i.xml           #加载配置文件
virsh start win7-10.$i                           #开启虚拟机
done