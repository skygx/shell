#!/bin/bash
#基础信息
# v1.8-20220613
# v1.8调整磁盘检查项，处理软盘识别异常问题，新增fstab磁盘挂载配置文件检查
export LANG=en_US.utf8
hostname=`hostname`
date=`date "+%Y-%m-%d %H:%M:%S"`
scriptversion="install_check_v1.8-20220613"

# 查询端口
check_ports(){
  declare -A ports_dic
  ports_dic=([3306]="mysql" [9210]="前置" [9220]="前置中转" [9310]="规则管理" [9300]="规则引擎" [9250]="action引擎" [2020]="python action执行引擎" [9230]="playbook执行引擎" [9290]="openapi" [9100]="管理平台" [9110]="report" [443]="https" [80]="http" [2019]="ai服务" [5001]="syslog接入-client" [8082]="syslog接入-master" [9400]="es" [2181]="zookeeper" [9092]="kafka")
  ports_list=("3306" "9210" "9220" "9310" "9300" "9250" "2020" "9230" "9290" "9100" "9110" "443" "80" "2019" "5001" "8082" "9400" "2181" "9092")
  check_num=0
  for port in ${ports_list[*]}
  do
    check_port=`ss -antlp | grep $port' ' | grep LISTEN`
    if [ -n "$check_port" ]
    then 
      check_port_str=$check_port_str"!ERROR $port 端口被占用，将影响 \033[41;37m ${ports_dic[$port]} \033[0m 服务安装部署！！\n"
      check_num=1
    fi 
  done

  if [ $check_num -eq 0 ]
  then 
      check_port_str="所需端口未被占用，不影响安装！"
  fi 
  echo -e "$check_port_str"
}

# 查询进程
check_process(){
  process_list=("elastic" "zookeeper" "kafka" "mysql" "nginx")
  check_num=0
  for process in ${process_list[*]}
  do
    check_proc=`ps -ef | grep $process | grep -v grep`
    if [ -n "$check_proc" ]
    then 
          check_proc_str=$check_proc_str"!WARN \033[43;37m $process \033[0m服务已安装，可能影响HoneyGuide系统安装部署！！\n"
          check_num=1
    fi 
  done
  if [ $check_num -eq 0 ]
  then 
      check_proc_str="未发现HG相关进程，可继续执行HoneyGuide系统安装部署！"
  fi 
  echo -e "$check_proc_str"
}

# 检测daemon
check_daemon(){
  status=`id daemon 2>&1`
  str=`echo $status | grep "no such user" `
  if [[ $str != "" ]]; then
    daemon_str="!ERROR \033[41;37m daemon 用户异常，请检查daemon用户是否存在 \033[0m"
  else
    daemon_str="daemon 用户状态正常"
  fi
}

# 检测hosts
check_hosts(){
  chk_host="$(grep -i $(hostname) /etc/hosts)"
  if [[ $chk_host != "" ]]; then
    echo "hosts文件内容正常。"
  else
    echo -e "!WARN \033[43;37m hosts文件内容异常，请手动添加记录 \"127.0.0.1   $(hostname)\" \033[0m"
    echo -e "\033[43;37m 添加记录命令：echo \"127.0.0.1   $(hostname)\" >> /etc/hosts  \033[0m"
    echo -e "当前hosts文件内容如下：\n\nhosts文件内容:"
    cat /etc/hosts
  fi
}

# 检查umask及/etc/profile
check_umask(){
  #获取用户umask
  user_umask=`umask`
  if [ $user_umask -eq 0022 ]
  then 
      user_umaskstr="用户umask值符合要求，用户umask值：$user_umask"
  else 
      user_umaskstr="!ERROR \033[41;37m 用户umask值不符合要求，用户umask值：$user_umask ,建议设置为0022 \033[0m"
      user_umasknum=0
  fi 

  # 检查umask及/etc/profile
  source /etc/profile
  if [[ $? != 0 ]]; then
    echo "!ERROR /etc/profile source执行异常，请检查/etc/profile配置文件";
    exit 1;
  fi

  # 获取系统umask
  umask=`umask`
  if [ $umask -eq 0022 ]
  then 
      umaskstr="系统umask值符合要求，系统umask值：$umask"
  else 
      umaskstr="!ERROR \033[41;37m 系统umask值不符合要求，系统umask值：$umask ,建议设置为0022 \033[0m"
      umasknum=0
  fi
}

# 查询防火墙状态
check_firewall(){
    # 获取防火墙状态
    filewalld=`systemctl status firewalld | grep Active | awk '{print $2}'`
    if [ $filewalld = "active" ]
    then 
        fwport=`firewall-cmd --zone=public --list-ports`
        fwstr="防火墙已启动，已开放端口：$fwport"
    else 
        fwstr="!WARN \033[43;37m 防火墙未启动，建议启用防火墙保障系统安全！\033[0m  \n!WARN \033[43;37m 注意：如安装资产模块必须启用防火墙 \033[0m"
        fwnum=0
    fi 
}

# 查询磁盘空间
check_space(){
  devs=`lsblk -d -o NAME | grep -v sr | grep -v fd | awk '{if (NR>1){print "/dev/"$1}}'`
  unused_space=0
  for i in $devs; do
      # 查询总磁盘空间
      disk=`fdisk -l 2>&1| grep $i | awk -F': ' '{print $2}' | awk -F' ' '{print $1}'`
      # disk=`parted -l 2>&1| grep $i | awk -F': ' '{print $2}' | awk -F'GB' '{print $1}'`
      sum=`echo $disk | awk -F '.' '{print $1}'`
      allspace=$[$allspace+$sum]

      # 查询 已使用 及 未分配 磁盘空间
      status=`fdisk -l $i"1" 2>&1`
      str=`echo $status | grep "No such file"`
      space=`fdisk -l 2>&1| grep $i | awk -F': ' '{print $2}' | awk -F' ' '{print $1}'`
      if [[ $str != "" ]]; then
        if echo $space|grep "\." >/dev/null 2>&1
        then
          sum=`echo $space | awk -F '.' '{print $1}'`
          unused_space=$[$unused_space+$sum]
        else
          unused_space=$[$unused_space+$space]
        fi
      else
        sum=`echo $space | awk -F '.' '{print $1}'`
        use_space=$[$use_space+$sum]
      fi
  done

  echo "磁盘空间总量为：$allspace G，已挂载使用空间：$use_space G，未挂载空间：$unused_space G"

  # 查询校验opt空间
  optspace=`df -h /opt | sed -n '2p' | awk -F' ' '{print $4}'|  awk -F'G' '{print $1}'`
  checkopt=`echo $optspace | grep -i 't'`
  if [[ $checkopt != "" ]]; then
    echo "磁盘空间为：$allspace G，/opt目录空间：$optspace，已满足安装条件"
  else
    if [[ $allspace -ge $disktotal ]]; then
      if [[ $optspace -ge $opttotal ]]; then
        echo "磁盘空间为：$allspace G，/opt目录空间：$optspace G，已满足安装条件"
      else
        all=$[$optspace+$unused_space]
        if [[ $all -gt $opttotal ]]; then
          unusedstr="!WARN 存在可用未挂载磁盘，挂载后可满足安装条件，建议挂载使用"
        else
          unusedstr="!WARN 可用未挂载磁盘空间为：$unused_space G，无法满足安装条件，建议添加新硬盘"
        fi
        echo -e "!WARN 磁盘空间为：$allspace G，/opt目录空间：$optspace G，\033[43;37m /opt目录空间未满足安装条件，建议调整磁盘空间分配 \033[0m "
        echo -e "!WARN \033[43;37m $unusedstr \033[0m "
      fi
    else
      echo -e "!WARN \033[43;37m 磁盘空间不足，未满足安装条件；当前磁盘空间为：$allspace G，建议磁盘空间为 $disktotal G。\033[0m"
    fi
  fi

  # 查询校验tmp空间
    tmpspace=`df -h /tmp | sed -n '2p' | awk -F' ' '{print $4}'|  awk -F'G' '{print $1}'`
    tmp=10
    if [[ $tmpspace -ge $tmp ]]; then
        echo "/tmp磁盘空间为：$tmpspace G，已满足安装条件"
    else
      echo "!WARN \033[43;37m /tmp磁盘空间为：$tmpspace G，不满足安装条件 \033[0m"
    fi
}

# 检测fstab
check_fstab(){
  status=`mount -a 2>&1`
  if [[ $status != "" ]]; then
    fstab_status="!ERROR \033[41;37m fstab文件异常请及时处置 \033[0m"
  else
    fstab_status="磁盘挂载配置正常"
  fi
}

# 基础信息检查
base_check(){ 
  # 系统启动时间
  startTime=`date -d "$(awk -F. '{print $1}' /proc/uptime) second ago" +"%Y-%m-%d %H:%M:%S"`
  
  # 获取系统版本
  ver=`cat /etc/redhat-release | awk -F' ' '{print $(NF-1)}'`
  version=${ver:0:3}
  #if [ `echo "$version > 7.2"|bc` -eq 1 ] && [ `echo "$version <= 7.9"|bc` -eq 1 ] ; 
  if [ `echo $version 7.3 | awk '{if($1>=$2) {print 1}}'` ] && [ `echo $version 7.9 | awk '{if($1<=$2) {print 1}}'` ] ;
  then
    versionstr="系统版本符合要求，当前系统版本："$version
  else
    versionstr="!ERROR \033[41;37m 系统版本不符合要求，建议为RHEL 7.4-7.9，当前系统版本：$version \033[0m"
  fi

    #获取内存总量
    mem_total=`free -h | grep Mem | awk '{print $2}'`
    total=`free | grep Mem | awk '{print $2}'`
    if [ $total -gt $memtotal ]
    then 
        memstr="内存大小符合要求，物理内存总量：$mem_total"
    else 
        memstr="!ERROR \033[41;37m 内存大小不符合要求，物理内存总量：$mem_total ,建议大小为 $memdefault G \033[0m"
    fi 
  
    # 获取cpu信息
    cpu_info=` cat /proc/cpuinfo | grep avx | wc -l`
    if [ $cpu_info -gt 0 ]
    then 
        cpustr="CPU已支持AVX指令集"
    else 
        cpustr="!WARN \033[43;37m CPU不支持AVX指令集，将无法使用AI功能，请知悉！\033[0m"
    fi 
  cpus=`lscpu | grep "CPU(s):" | sed -n '1p' | awk -F' ' '{print $2}'`
  if [ $cpus -ge $cputotal ]
  then 
      cpusstr="CPU核心数已符合需求"
  else 
      cpusstr="!WARN \033[41;37m CPU核心数不符合需求，建议为 $cputotal 核以上 \033[0m"
  fi

  #判断IP地址是否为动态获取
  ipdhcp=`ip addr | grep ens | grep dynamic`
  if [[ ! -n $ipdhcp ]]; then
    ipstr="IP地址正常"
  else
    ipstr="!WARN \033[43;37m IP地址可能为动态获取，建议配置为静态IP地址，请手动确认  \033[0m"
  fi
  
  check_umask
  check_daemon
  check_fstab
  # 输出结果
  echo $scriptversion
  echo -e "\n\n主机名："$hostname
  echo -e "系统版本：$versionstr"
  echo "系统启动时间：$startTime"
  echo "自检时间："$date
  echo -e $user_umaskstr 
  echo -e $umaskstr
  echo -e $memstr
  echo -e $cpustr
  echo -e $cpusstr
  echo -e $ipstr
  echo -e $daemon_str
  check_space
  echo -e $fstab_status
  check_firewall
  check_ports
  check_process
  echo -e $fwstr
  check_hosts
}

# 检测是否安装
check_install(){
    if [ -f "/opt/shakespeare/version" ]; then
        check_res=1
      version=`cat /opt/shakespeare/version | grep version | awk -F'=' '{print $2}'`
      echo "HG系统版本为：$version"
      else
        check_res=0
      fi
}

# 环境字段初始
environment(){
  echo "
  1.POC(测试环境检查)
  
  2.PRO(正式交付环境检查)
  "
  read -p " 请输入您的操作(默认为：POC)：" c
  
  if [ "$c" = 2 ];then
    echo "正式交付环境检查"
    cputotal=16
    memtotal=65011712
    memdefault=64
    disktotal=1000
    opttotal=800
  else
    echo "POC测试环境检查"
    cputotal=8
    memtotal=32505856
    memdefault=32
    disktotal=500
    opttotal=400
  fi

}

home(){
  clear
  echo -e "即将开始HG部署前自检"
  sleep 1
  check_install
  environment
  sleep 1
  if [ $check_res -eq 1 ]; then
    read -p "检测到honeyguide系统已完成安装，是否继续进行检查！[Y/N](defult:N)" conopt
    if [ "$conopt" = "Y" ] || [ "$conopt" = "y" ];then
      echo "-----开始自检-----"
      base_check
      sleep 1
      echo "-----自检完成-----"
    else
      echo "-----结束自检-----"
    fi
  else
    echo "-----开始自检-----"
      base_check
      sleep 1
    echo "-----自检完成-----"
  fi
}
home
