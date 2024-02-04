#!/bin/bash

ifs=(`ifconfig | grep "^e" | awk -F: '{print $1}'`)

for i in $(echo ${ifs[@]});do
echo -e "${i}\n`ifconfig ${i} | awk 'NR==2{print $2}'`"
done
