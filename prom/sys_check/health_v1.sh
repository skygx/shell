#!/bin/bash
# 获取当前时间
DATE=$(date "+%Y-%m-%d %H:%M:%S")
HEALTH="True"
STATUS=""

LOAD_THRESHOLD=$(cat /proc/cpuinfo | grep "cpu cores"|sort|uniq|awk -F":" '{print $2}')
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=90
IO_THRESHOLD=90
#FILE_THRESHOLD=$(ulimit -n)
FILE_THRESHOLD=10000
NET_THRESHOLD=1000
INODE_THRESHOLD=80

APP_NAME="nginx"
PORT_NUM="80"

server_status(){
# 检查系统的负载平均值
LOAD_AVERAGE=$(uptime | awk '{print $10}')
if (( $(echo "$LOAD_AVERAGE > $LOAD_THRESHOLD" | bc -l) )); then
  # 如果负载平均值超过阈值，则发送电子邮件警报
  HEALTH="FALSE"
  STATUS="$STATUS 检测到高系统负载平均值: $LOAD_AVERAGE\n"
fi

# 检查系统的CPU使用率
CPU_USAGE=$(echo "100 - $(top -bn 1|awk '/Cpu\(s\)/{print $8}')"|bc -l)
if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
  # 如果负载平均值超过阈值，则发送电子邮件警报
  HEALTH="FALSE"
  STATUS="$STATUS 检测到CPU使用率: $CPU_USAGE\n"
fi

# 检查磁盘使用情况
DISK_USAGE=$(df -h | awk '/\/dev\/mapper/{print $5}')
if (( ${DISK_USAGE%?} >= $DISK_THRESHOLD )); then
  HEALTH="FALSE"
  STATUS="$STATUS 在检测到高磁盘使用率: $DISK_USAGE\n"
fi

# 检查系统的IO使用率
IO_USAGE=$(iostat -x 1 1 | awk '/sda/{print $14}')
if (( $(echo "$IO_USAGE > $IO_THRESHOLD" | bc -l) )); then
  HEALTH="FALSE"
  STATUS="$STATUS 检测到IO使用率: $IO_USAGE\n"
fi

# 检查内存使用情况
MEMORY_USAGE=$(free -m | grep Mem | awk '{printf "%.2f",$3/$2*100.0}')

if (( $(echo "$MEMORY_USAGE > $MEM_THRESHOLD" | bc -l) )); then
  HEALTH="FALSE"
  STATUS="$STATUS 检测到高内存使用率: $MEMORY_USAGE%\n"
fi

# 检查文件打开数情况
File_USAGE=$(cat /proc/sys/fs/file-nr|cut -f 1)

if (( $(echo "$File_USAGE > $FILE_THRESHOLD" | bc -l) )); then
  HEALTH="FALSE"
  STATUS="$STATUS 检测到文件使用数: $File_USAGE\n"
fi

# 检查网络连接数情况
NET_USAGE=$(netstat -nltua|wc -l)

if (( $(echo "$NET_USAGE > $NET_THRESHOLD" | bc -l) )); then
  HEALTH="FALSE"
  STATUS="$STATUS 检测到网络连接数: $NET_USAGE\n"
fi

# 检查inode数情况
INODE_USAGE=$(df -i -t xfs |awk '/mapper/{print $5}'|tr % ' ')

if (( $(echo "$INODE_USAGE > $INODE_THRESHOLD" | bc -l) )); then
  HEALTH="FALSE"
  STATUS="$STATUS 检测到INODE使用率: $INODE_USAGE\n"
fi
}

project_status(){
# 检查APP进程情况
APP_STATUS=$(ps -ef | grep $APP_NAME | grep -v grep | wc -l)
if [ $APP_STATUS -eq 0 ]; then
  HEALTH="FALSE"
  STATUS="$STATUS 检测到 $APP_NAME 进程不存. \n"
fi

# 检查PORT端口情况
PORT_STATUS=$(netstat -nalt | grep -E ":$PORT_NUM\>" | grep -v grep | wc -l)
if [ $PORT_STATUS -eq 0 ]; then
  HEALTH="FALSE"
  STATUS="$STATUS 检测到 $PORT_NUM 端口号不存. \n"
fi
}

server_status
project_status

if [ $HEALTH == "FALSE" ];then
   echo -e "$STATUS ERROR"
   exit 1
else
    echo "OK"
    exit 0
fi
