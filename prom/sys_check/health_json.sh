#!/bin/bash
ports_list=(80 3306 10000 18080)
process_list=(elastic zookeeper mysqld nginx)

echo_green(){
printf "\e[32m %b \e[0m\n" "$1"
}
echo_red(){
printf "\e[31m %b \e[0m\n" "$1"
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

set_global_value(){
    export  hostname=$(hostname)
    export  ip=$(hostname -i)
    export start_time=$(who -b | awk '{print $3,$4}')
    export run_time=$(uptime | awk '{print $3 " "}' | sed 's/,//g')
	export	cpu_util=$(top -bn 1|awk '/Cpu\(s\)/{print $2+$4}')
        free_total=`free -m | grep Mem|awk '{printf $2}'`
        free_used=`free -m | grep -v Swap|awk 'END{printf $3}'`
	export  mem_util=$(echo "scale=2;($free_used/$free_total)*100"|bc)
	free_total=`free -m | grep Swap|awk '{printf $2}'`
    free_used=`free -m | grep Swap|awk 'END{printf $3}'`
     [ $free_total != 0 ] && export swap_util=`echo "scale=2;($free_used/$free_total)*100"|bc` || swap_util=0
    export disk_util=$(df -h -t xfs|awk 'NR>1 {printf ("%s: %s\n"),$1,$5}')
    export net_conn=$(netstat -nalt | awk 'NR>2 {++S[$NF]} END {for(a in S) printf "%s:%d\n",a,S[a]}' | awk '{printf ("%s,%d\n"),$1,$2}')
    export io_util=$(iostat -x 1 1|grep 'sd'|awk '{printf ("%s:%.2f\n"),$1,$14}')
}
set_global_value

data_dic='{
        "hostname": "'"$hostname"'",
        "ip": "'"$ip"'",
        "start_time": "'"$start_time"'",
        "run_time": "'"$run_time"'",
        "cpu_util": "'"$cpu_util"'",
       "mem_util": '"$mem_util"',
	   "swap_util": "'"$swap_util"'",
	   "disk_util": "'"$disk_util"'",
	   "net_conn": "'"$net_conn"'",
	   "io_util": "'"$io_util"'"
	   }'
echo $data_dic > /root/shell_test/sys_check/data.json
