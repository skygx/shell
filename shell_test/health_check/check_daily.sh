#!/bin/sh
# sh check_daily.sh 80 40 20 85 80 /root/shell_test/health_check/temp

#. /home/ap/opsware/agent/scripts/bsap_script/BSAP_AUTO_COMMON.sh $*

temp_dir=$6
if [ ! -d $temp_dir ];then
	mkdir -p ${temp_dir}
fi

##################磁盘巡检##########################
disk_threshold=$1
disk_flag=false
mount_point=mount-point
df -h | awk '$1 !~ "tmpfs" {printf "%s\n", $0}' | awk 'NR!=1{print $0}' > ${temp_dir}/disk_usage.txt

while read line
do
	echo "读入的df命令结果：$line"
	usage=`echo $line | awk '{print $5}' | cut -d'%' -f1`
	if (echo ${usage} ${disk_threshold} | awk '($1<$2){exit 1}');then
		mount_point_1=`echo $line | awk '{print $6}'`
#		saveResult "disk_usage: $mount_point_1" "$usage"
		mount_point=${mount_point}:`echo $line | awk '{print $6}'`
		disk_flag=true
	fi
done < ${temp_dir}/disk_usage.txt

##################inode使用率巡检##########################
inode_threshold=$2
inode_flag=false
inode_point=inode-point
df -i | awk '$1 !~ "tmpfs" {printf "%s\n", $0}' | awk 'NR!=1{print $0}' > ${temp_dir}/inode_usage.txt

while read line
do
	echo "读入的df -i命令结果：$line"
	inode_usage=`echo $line | awk '{print $5}' | cut -d '%' -f1`
	if (echo ${inode_usage} ${inode_threshold} | awk '($1<$2){exit 1}');then
		inode_point_1=`echo $line | awk '{print $6}'`
#		saveResult "inode_usage: ${inode_point_1}" "${inode_usage}"
		inode_point=${inode_point}:`echo $line | awk '{print $6}'`
		inode_flag=true
	fi
done < ${temp_dir}/inode_usage.txt

##################CPU巡检##########################
cpu_idle_threshold=$3
cpu_idle=`top -bn 1 | grep "%Cpu(s)" | awk -F"ni," '{print $2}' | awk '{print $1}'`
cpu_flag=false
echo "cpu空闲率: $cpu_idle"
#if (echo $cpu_idle $cpu_idle_threshold | awk '($1<$2){exit 1}');then
#if [ $cpu_idle -lt $cpu_idle_threshold ];then
#if [ `expr $cpu_idle \< $cpu_idle_threshold` -eq 0 ];then
if (( $(echo "$cpu_idle < $cpu_idle_threshold" | bc -l) ));then

	cpu_flag=true
	echo "cpu 空闲率低：$cpu_idle"
	#############输出占用CPU较高的进程#############
		top -bn 1 -o %CPU| sed -n '/%MEM/,+2p'
#		saveResult "CPU_idle" "$cpu_idle"
fi

##################内存巡检##########################
mem_total=`cat /proc/meminfo | grep -i MemTotal | awk '{print $2}'`
mem_free=`cat /proc/meminfo | grep -i MemAvailable | awk '{print $2}'`
mem_used=$(echo $mem_total $mem_free | awk '{printf $1-$2}')
mem_used_threshold=$4
mem_used_percent=$(echo $mem_used $mem_total | awk '{printf "%.2f",$1/$2 * 100}')
mem_flag=false
echo "内存使用率：$mem_used_percent"

if (echo $mem_used_percent $mem_used_threshold | awk '($1<$2){exit 1}');then
	echo "内存使用率高：$mem_used_percent"
	#############输出占用内存较高的进程#############
		top -bn 1 -o %MEM | sed -n '/%MEM/,+2p'
	mem_flag=true
#	saveResult "mem_used" "$mem_used_percent"
fi

##################swap巡检##########################
swap_total=`cat /proc/meminfo | grep -i swaptotal | awk '{print $2}'`
swap_free=`cat /proc/meminfo | grep -i swapfree | awk '{print $2}'`
swap_free_percent=$(echo $swap_free $swap_total | awk '{printf "%.2f",$1/$2 * 100}')
swap_free_threshold=$5
swap_flag=false
echo "swap空闲率: $swap_free_percent"
if (echo $swap_free_percent $swap_free_threshold | awk '($1>$2){exit 1}');then
	echo "swap空闲率低：$swap_free_percent"
	swap_flag=true
#	saveResult "swap_free" "$swap_free_percent"
fi

############判断输出情况###########
if [ "true" = "$disk_flag" ];then
	echo "exist disk usage > ${disk_threshold}%"
	echo "disk使用率较高的挂载点：$mount_point"
	exit -1
fi

if [ "true" = "$inode_flag" ];then
	echo "exist inode usage > ${inode_threshold}%"
	echo "inode使用率较高的挂载点：$inode_point"
	exit -1
fi

if [ "true" = "$cpu_flag" ];then
	echo "cpu idle percent < $cpu_idle_threshold"
	exit -1
fi

if [ "true" = "$mem_flag" ];then
	echo "mem used percent > $mem_used_threshold"
	exit -1
fi

if [ "true" = "$swap_flag" ];then
	echo "swap free percent < $swap_free_threshold"
	exit -1
fi

exit 0
