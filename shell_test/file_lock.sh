#!/bin/bash
#*/1 * * * * flock -xn /dev/shm/test.lock -c "sh /root/shell_test/file_lock.sh >> /tmp/test_tmp.log"
echo "--------------------------------"
echo "start at `date '+%Y-%m-%d %H:%M:%S'`  ..."
sleep 140s
echo "finished at `date '+%Y-%m-%d %H:%M:%S'`  ..."
