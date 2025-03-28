#!/bin/bash

#time timeout 5 ./timeout.sh

cnt=$(($RANDOM % 7 + 2))
echo "count is $cnt"
ping -c $cnt www.baidu.com
