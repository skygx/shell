#!/bin/bash

CPU_USAGE=$(top -bn 1|awk '/Cpu/ {if(NR<5){print $2}}')
MEM_USAGE=$(free -m | awk '/Mem/ {printf "%.2f",$3/$2*100}')

echo $CPU_USAGE
echo $MEM_USAGE
