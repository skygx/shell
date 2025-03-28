#!/bin/bash

workdir='/root/shell_test/sys_check'
health_file='health_check.sh'
send_mail='send_mail.sh'
check_file='check.txt'

cd $workdir

sh $health_file > $check_file
echo "$(date '+%F %T') health check done."

sleep 5
sh $send_mail
echo "$(date '+%F %T') send mail done."
