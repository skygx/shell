#!/bin/bash

#to="sweet_love2000@126.com,guoxin@git.com.cn"
to="sweet_love2000@126.com"
subject="health check"
RESULTFILE='check.txt'
echo -e "`date "+%Y-%m-%d %H:%M:%S"` 健康巡检报告"  | mail -a $RESULTFILE -s "健康巡检报告" sweet_love2000@126.com
#cat check.txt | mail -s "$(echo -e "$subject\nContent-Type: text/plain; charset=utf-8")" "$to"
#mail -s "$(echo -e "$subject")" "$to" < check.txt
