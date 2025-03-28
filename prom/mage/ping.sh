#!/bin/bash

ip=$1
ping -c1 -W1 $ip &> /dev/null && echo "$ip is up" || (echo "$ip is unreachable"; exit 1)
