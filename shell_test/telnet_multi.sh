#!/bin/sh

port=21
cat ./iplist.txt | while read line
do
	result=$(echo -e "\n" | telnet $line $port | grep "Connected" >/dev/null )
	if [ $? -eq 0 ];then
	  echo "$line $port Network is Open"
	else
	  echo "$line $port Network is Close"
	fi
done
touch testsss
