#!/bin/bash
ports_list=(80 3306 10000 18080)
process_list=(elastic zookeeper mysqld nginx)


echo_green(){
printf "\e[32m %b \e[0m\n" "$1"
}
echo_red(){
printf "\e[31m %b \e[0m\n" "$1"
}



sys_check(){
        echo "主机名称：`hostname`"
        #echo "操作系统：`cat /etc/*-release|awk 'END{print}'`"
        echo "操作系统：`cat /etc/*-release|awk 'END{print}'|cut -d \= -f 2|sed 's/\"//g'`"
        echo "系统内核：`uname -r`"
        #echo "SELinux：`/usr/sbin/sestatus | grep 'SELinux status:' | awk '{print $3}'`"
        echo "系统语言：`echo $LANG |awk -F "." '{print $1}'`"
        echo "系统编码：`echo $LANG |awk -F "." '{print $2}'`"
        echo "当前时间：`date +%F_%T`"
        echo "启动时间：`who -b | awk '{print $3,$4}'`"
        echo "运行时间：`uptime | awk '{print $3 " "}' | sed 's/,//g'`"
        }

cpu_Info(){
        echo "CPU架构：`uname -m`"
        echo "CPU型号：`cat /proc/cpuinfo | grep "model name" | uniq|awk -F":" '{print $2}'`"
        echo "CPU数量：`cat /proc/cpuinfo | grep "physical id"|sort|uniq|wc -l` 颗"
        echo "CPU核心：`cat /proc/cpuinfo | grep "cpu cores"|sort|uniq|awk -F":" '{print $2}'` 核"
        echo "CPU线程：`cat /proc/cpuinfo | grep "processor" | awk '{print $3}'| sort | uniq | wc -l` 线程"

        }

cpu_Check(){
        Check_Res=`sar -u 1 2 |grep Average`
        echo "CPU用户占比：`echo $Check_Res|awk '{printf $3}'`%"
        echo "CPU内核占比：`echo $Check_Res|awk '{printf $5}'`%"
        echo "CPU使用占比：`echo $Check_Res|awk '{printf $3+$5}'`%"
        echo "CPU可用占比：`echo $Check_Res|awk '{printf $8}'`%"
        }


mem_check(){
        free_total=`free -m | grep Mem|awk '{printf $2}'`
        free_used=`free -m | grep -v Swap|awk 'END{printf $3}'`
        #free_available=`free -m | grep Mem|awk '{printf $4}'`
        #used_baifen=`echo "scale=2;$free_used/$free_total*100"|bc`
        echo "内存合计：`free -m | awk "NR==2"| awk '{print $2}'` MB "
        echo "内存使用：`free -m | grep -v Swap | awk 'END{print $3}'` MB"
        #echo "内存buff/cache：`free -g | awk "NR==2"| awk '{print $6}'` GB"
        #echo "内存使用：`free -m | awk "NR==2"| awk '{printf ("%.2f\n", ($3+$6)/1024)}'` GB 占比 `echo "scale=2;$free_used/$free_total*100"|bc`%"
        echo "Mem使用率： `echo "scale=2;($free_used/$free_total)*100"|bc`%"
        # echo "内存使用：`free -mh | awk "NR==2"| awk '{print $3+$6}'` G占比 `echo "scale=2;$free_used/$free_total*100"|bc`%"
        #echo "内存可用：`free -g | awk "NR==2"| awk '{print $4}'` GB 占比 `echo "scale=2;$free_available/$free_total*100"|bc`% "
        #echo "内存可用：`free -g | awk "NR==2"| awk '{print $4}'` GB 占比 `echo "scale=2;$free_available/$free_total*100"|bc`% "
        }
swap_check(){
        free_total=`free -m | grep Swap|awk '{printf $2}'`
        free_used=`free -m | grep Swap|awk 'END{printf $3}'`
        echo "swap合计：`free -m | awk "NR==3"| awk '{print $2}'` MB "
        echo "swap使用：`free -m | grep Swap | awk 'END{print $3}'` MB"
	if [ $free_total != 0 ]
	then
        echo "swap使用率： `echo "scale=2;($free_used/$free_total)*100"|bc`%"
	else
	echo "swap未使用"
	fi
        }

disk_Check(){

        #echo "`df -h | sort |grep -E "/sd|/mapper" |awk '{printf ("磁盘使用率：分区 %-25s  , 合 计 %-5s 已用 %-5s  剩余 %-5s  使用占比 %-3s\n"),$1,$2,$3,$4,$5}'`"
        echo "`df -h -t xfs|awk 'NR>1 {printf ("磁盘使用率：分区 %-25s  , 合 计 %-5s 已用 %-5s  剩余 %-5s  使用占比 %-3s\n"),$1,$2,$3,$4,$5}'`"

       # echo "`df -h | sort |grep /sd |awk '{print "ResCheck_DiskRate：分区" $1 ," 合计"$2" 已用" $3 " 剩余"$4 " 使用占比 " $5}'`"
        }

ip_Addr(){

        echo "`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6 |awk -F " " 'BEGIN {count=0} {count=count+1; print "IP地址" count "：" $2}'`"
}

port_Check(){
#        local service_port=50456
        ports=($@)
	for service_port in ${ports[*]}
	do
        Temp_S=`netstat -naut | grep -E ":$service_port\>"`
        if [ -z "$Temp_S" ]; then
                #echo_red "Check_Port：$service_port  Unknown"
                echo "Port：$service_port  Unknown"
        fi

        if [ -n "$Temp_S" ]; then
                #echo `echo $Temp_S|awk '{  print "ResCheck_Port：" service_port " " $6}' service_port=$service_port `
                #echo_green "Check_Port：$service_port  LISTEN"
                echo "Port：$service_port  LISTEN"
        fi
	done


}

process_Check(){
  process_list=($@)
  check_num=0
  for process in ${process_list[*]}
  do
    check_proc=`ps -ef | grep $process | grep -v grep`
    if [ -n "$check_proc" ]
    then
	echo "Process：$process  on" 
    else
	echo "Process：$process  down" 
    fi
  done
}

url_Check(){
        #通过端口的返回值判断状态

        url_path=$1

        #local url_path="https://asts.cxmt.com:8080"
        #echo `curl -k -s --head $url_path |awk 'NR==1 {print "ResCheck_URL：" url_path " "$2$3}' url_path=$url_path`
        url_checkRes=`curl  --connect-timeout 3 -k -s --head $url_path`
        if [ "$url_checkRes" ]; then
              echo `curl -k -s --head $url_path |awk 'NR==1 {print "Check_URL：" url_path " "$2" "$3}' url_path=$url_path`
        else
              echo "Check_URL：$url_path  Unreachable "
        fi
}

net_Check(){
        echo "`netstat -nalt | awk 'NR>2 {++S[$NF]} END {for(a in S) printf "%s %d\n",a,S[a]}' | awk '{printf ("网络连接状态：%-15s 数量：%-d\n"),$1,$2}'`"
<<EOF	
	for key in $(netstat -nalt | awk 'NR>2 {++S[$NF]} END {for(a in S) printf "%s%d\n",a,S[a]}')
	do
	status=${key%%[0-9]*}
	count=${key##*[^0-9]}
	printf "网络连接状态:%-15s 数量:%-d\n" $status $count
	done
EOF
}

io_Check(){
	echo -e "`iostat -x 1 1|grep 'sd'|awk '{printf ("磁盘：%-5s  IO使用率：%-4.2f \n"),$1,$14}'`"
}

set_global_value(){
	export	cpu_util=$(top -bn 1|awk '/Cpu\(s\)/{print $2+$4}')
        free_total=`free -m | grep Mem|awk '{printf $2}'`
        free_used=`free -m | grep -v Swap|awk 'END{printf $3}'`
	export  mem_util=$(echo "scale=2;($free_used/$free_total)*100"|bc)

}
set_global_value
head_list=("cpu" "mem")
data_list=("$cpu_util" "$mem_util")

head=$(IFS=","; echo "${head_list[*]}")
data=$(IFS=","; echo "${data_list[*]}")

echo $head
echo $data

main(){
echo "$(date '+%F %T') start health check"
sys_check
cpu_Info
cpu_Check
mem_check
swap_check
disk_Check
ip_Addr
port_Check ${ports_list[*]}
process_Check ${process_list[*]}
url_Check http://192.168.226.20:80
net_Check
io_Check
}

