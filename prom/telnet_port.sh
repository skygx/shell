#!/bin/bash
 
# 目标主机
HOST="192.168.226.20"
 
# 端口范围
PORT_START=1
PORT_END=100
 
# 循环遍历端口范围并尝试连接
for PORT in `seq $PORT_START $PORT_END`; do
    echo "Testing $HOST on port $PORT"
    if telnet $HOST $PORT <<< quit 2> /dev/null | grep -i 'Connected'; then
        echo "$HOST:$PORT is open"
    else
        echo "$HOST:$PORT is closed"
    fi
done
