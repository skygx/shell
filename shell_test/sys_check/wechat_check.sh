#!/bin/bash
 
# 设置告警阈值，单位为百分比
MEM_THRESHOLD=80
DISK_THRESHOLD=90
NET_THRESHOLD=80
IO_THRESHOLD=50
CPU_THRESHOLD=80
EMAIL="sweet_love2000@126.com"
 
# 获取内存使用率
MEM_USED=$(free | awk 'FNR == 2 {print $3}')
MEM_TOTAL=$(free | awk 'FNR == 2 {print $2}')
MEM_USAGE=$((100 * $MEM_USED / $MEM_TOTAL))
 
# 获取磁盘使用率
DISK_USAGE=$(df -h -t xfs |grep mapper| awk '{sub(/%/, ""); print $5}')
NET_USAGE=$(ifstat | awk '$1=="ens33"{print $8}')
IO_USAGE=$(iostat | awk '$1=="sda"{print $4}')
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}')
 
  mail_message=""
  mail_message=$mail_message"Memory usage is above threshold ($MEM_THRESHOLD%): $MEM_USAGE%\n"
  mail_message=$mail_message"Disk usage is above threshold ($DISK_THRESHOLD%): $DISK_USAGE%\n" 
  mail_message=$mail_message"Net usage is above threshold ($NET_THRESHOLD%): $NET_USAGE%\n" 
  mail_message=$mail_message"IO usage is above threshold ($IO_THRESHOLD%): $IO_USAGE%\n"
  mail_message=$mail_message"CPU usage is above threshold ($CPU_THRESHOLD%): $CPU_USAGE%\n" 
  echo -e $mail_message | mail -s "usage alert" $EMAIL
  echo -e $mail_message

# 检查内存使用率是否超过阈值
if [ $MEM_USAGE -ge $MEM_THRESHOLD ]; then
  # 发送告警邮件
  echo "Memory usage is above threshold ($MEM_THRESHOLD%): $MEM_USAGE%" | mail -s "Memory usage alert" $EMAIL
fi
 
# 检查磁盘使用率是否超过阈值
if [ ${DISK_USAGE%?} -ge $DISK_THRESHOLD ]; then
  # 发送告警邮件
  echo "Disk usage is above threshold ($DISK_THRESHOLD%): $DISK_USAGE" | mail -s "Disk usage alert" $EMAIL
fi
