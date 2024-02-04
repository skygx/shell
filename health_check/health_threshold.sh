#!/bin/bash
# 设置发送警报的邮件地址
EMAIL_ADDRESS="your_email@example.com"

# 获取当前时间
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# 检查系统的负载平均值
LOAD_AVERAGE=$(uptime | awk '{print $10}')
THRESHOLD=2

if (( $(echo "$LOAD_AVERAGE > $THRESHOLD" | bc -l) )); then
  # 如果负载平均值超过阈值，则发送电子邮件警报
  echo "在 $DATE 检测到高系统负载平均值: $LOAD_AVERAGE" | mail -s "服务器警报" $EMAIL_ADDRESS
fi

# 检查磁盘使用情况
DISK_USAGE=$(df -h | grep '/dev/sda1' | awk '{print $5}')
THRESHOLD=90

if (( ${DISK_USAGE%?} >= THRESHOLD )); then
  # 如果磁盘使用率超过阈值，则发送电子邮件警报
  echo "在 $DATE 检测到高磁盘使用率: $DISK_USAGE" | mail -s "服务器警报" $EMAIL_ADDRESS
fi

# 检查内存使用情况
MEMORY_USAGE=$(free -m | grep Mem | awk '{print $3/$2 * 100.0}')
THRESHOLD=90

if (( $(echo "$MEMORY_USAGE > $THRESHOLD" | bc -l) )); then
  # 如果内存使用率超过阈值，则发送电子邮件警报
  echo "在 $DATE 检测到高内存使用率: $MEMORY_USAGE%" | mail -s "服务器警报" $EMAIL_ADDRESS
fi
