#!/usr/bin/env bash
#set -x
#export PS4='+${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]} '

#echo "hello world"
#echo $(hostname)
echo $0 | sed -e 's#[\\/][^\\/][^\\/]*$##'
echo "$SHELL"
#echo "alias logs='cd /var/log'" >> ~/.bashrc
date
#touch /root/111.txt
echo "Hello $name"  

#ip=$(hostname -I|cut -d\  -f 1)
#
#ipa=${ip//./-}
#
#echo "$ipa"
#echo $ipa-ZXT.jar
#
#if [ -z $ip ]
#then
#echo "hello"
#else
#echo "wrong"
#fi
