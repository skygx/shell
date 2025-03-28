#!/bin/bash  

# 定义cpu函数，用于显示CPU使用率和等待磁盘IO的相应使用率  
function cpu(){  
    # 使用vmstat命令获取CPU的用户态和系统态使用率之和  
    util=$(vmstat | awk '{if(NR==3)print $13+$14}')  
    # 使用vmstat命令获取CPU的等待磁盘IO的相应使用率  
    iowait=$(vmstat | awk '{if(NR==3)print $16}')  
    # 输出CPU使用率和等待磁盘IO的相应使用率  
    echo "CPU -使用率:${util}% ,等待磁盘IO相应使用率:${iowait}%"  
}  
  
# 定义memory函数，用于显示内存的总大小、已使用量和剩余量  
function memory (){  
    # 使用free命令获取总内存大小（单位转换为G）  
    total=`free -m |awk '{if(NR==2)printf "%.1f",$2/1024}'`  
    # 使用free命令获取已使用的内存大小（单位转换为G）  
    used=`free -m |awk '{if(NR==2) printf "%.1f",($2-$NF)/1024}'`  
    # 使用free命令获取剩余的内存大小（单位转换为G）  
    available=`free -m |awk '{if(NR==2) printf "%.1f",$NF/1024}'`  
    # 输出内存的总大小、已使用量和剩余量  
    echo "内存 - 总大小: ${total}G , 使用: ${used}G , 剩余: ${available}G"  
}  
  
# 定义disk函数，用于显示硬盘的挂载点、总大小、已使用空间和使用率  
disk(){  
    # 使用df命令获取所有硬盘分区的设备名称  
    fs=$(df -h |awk '/^\/dev/{print $1}')  
    # 遍历每个硬盘分区  
    for p in $fs; do  
        # 使用df命令获取分区的挂载点  
        mounted=$(df -h |awk '$1=="'$p'"{print $NF}')  
        # 使用df命令获取分区的总大小  
        size=$(df -h |awk '$1=="'$p'"{print $2}')  
        # 使用df命令获取分区已使用的空间  
        used=$(df -h |awk '$1=="'$p'"{print $3}')  
        # 使用df命令获取分区的使用率  
        used_percent=$(df -h |awk '$1=="'$p'"{print $5}')  
        # 输出分区的挂载点、总大小、已使用空间和使用率  
        echo "硬盘 - 挂载点: $mounted , 总大小: $size , 使用: $used , 使用率: $used_percent"  
    done  
}  
  
# 定义tcp_status函数，用于显示TCP连接状态  
function tcp_status() {  
    # 使用ss命令获取TCP连接状态，并使用awk进行统计  
    summary=$(ss -antp |awk '{status[$1]++}END{for(i in status) printf i":"status[i]" "}')  
    # 输出TCP连接状态统计结果  
    echo "TCP连接状态 - $summary"  
}  
  
# 调用各个函数，显示相关信息  
cpu  
memory  
disk  
tcp_status
