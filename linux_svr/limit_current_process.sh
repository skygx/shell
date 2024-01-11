#!/bin/bash

CE_HOME='/data/ContentEngine'
LOG_PATH='/data/logs'

MAX_SPIDER_COUNT=8

count=$(ps -ef | grep -v grep | grep run.py | wc -l)

try_time=0
cd $CE_HOME
while [ $count -lt $MAX_SPIDER_COUNT -a $try_time -lt $MAX_SPIDER_COUNT ]
do
    let try_time+=1
    python run.py >> ${LOG_PATH}/spider.log 2>&1 &
    count=$(ps -ef | grep -v grep | grep run.py | wc -l)
done