#!/bin/bash
user='admin'
port='22'
local_dir='/root/test'
remote_dir='/root/test.bak'
host_file='hostlist.txt'
t_script="test.sh"

echo_green(){
printf "\e[32m %b \e[0m\n" "$1"
}
echo_red(){
printf "\e[31m %b \e[0m\n" "$1"
}
 
expect_com(){
command=$@
    expect <<EOF
      set timeout 3
      spawn -noecho $command
      expect {
        "yes/no" { send "yes\n";exp_continue }
        "password" { send "$passwd\n" }
      }
      expect {
	"password" { send "$passwd\n" }
      }
EOF
}
batch_ssh(){
command=$1
while read line
do
    [ ${line:0:1} = '#' ] && continue
    ip=`echo $line | cut -d " " -f 1`
    passwd=$(echo $line | cut -d " " -f 2)
    echo_green "$ip"
    expect_com "ssh -p $port $user@$ip $command"
    if [ $? -eq 0 ];then
	echo_green "$ip $command is ok."
    else
	echo_red "$ip $command is error."
    fi
    #sshpass -p $passwd ssh $user@$ip hostname
done <  hostlist.txt
}

batch_ssh_script(){
script=$1
while read line
do
    [ ${line:0:1} = '#' ] && continue
    ip=`echo $line | cut -d " " -f 1`
    passwd=$(echo $line | cut -d " " -f 2)
    echo_green "$ip"
    expect_com "sh -c {ssh -p $port -T $user@$ip < $script}"
    if [ $? -eq 0 ];then
	echo_green "$ip $script is ok."
    else
	echo_red "$ip $script is error."
    fi
    #sshpass -p $passwd ssh $user@$ip hostname
done <  hostlist.txt
}



batch_scp(){
while read line
do
    [ ${line:0:1} = '#' ] && continue
    ip=`echo $line | cut -d " " -f 1`
    passwd=`echo $line | cut -d " " -f 2`
    echo_green "$ip"
    expect_com  "scp -rq -P $port $local_dir $user@$ip:$remote_dir"
    if [ $? -eq 0 ];then
	echo_green "$ip scp is ok."
    else
	echo_red "$ip scp is error."
    fi
done <  hostlist.txt
}

batch_ssh_script $t_script
#batch_ssh ls /root
#batch_scp
