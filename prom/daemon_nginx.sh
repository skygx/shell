#! /bin/sh
#进程名字可修改
PRO_NAME="nginx"
#CMD="nohup bundle exec rails server webrick -p3000 -b 0.0.0.0 -e production >/dev/null 2>&1 -d &"
#CMD="date"
CMD=$(ps -u root | grep nginx)
while true ; do
     #用ps获取$PRO_NAME进程数量
     NUM=`ps -f -u root | grep -w ${PRO_NAME} | grep -v grep |wc -l`
     #echo $NUM
     #少于1，重启进程
     if [ "${NUM}" -lt 1 ];then
        echo "${PRO_NAME} was killed"
        #$CMD
    #大于1，杀掉所有进程，重启
    elif [ "${NUM}" -gt 1 ];then
        echo "more than 1 ${PRO_NAME},killall ${PRO_NAME}"
        killall -u root -9 $PRO_NAME
        #$CMD
     fi
     #kill僵尸进程
     NUM_STAT=`ps -u root -f | grep -w ${PRO_NAME} | grep T | grep -v grep | wc -l`
     if [ "${NUM_STAT}" -gt 0 ];then
         killall -u root -9 ${PRO_NAME}
         #$CMD
    fi
     sleep 5s
done

exit 0
