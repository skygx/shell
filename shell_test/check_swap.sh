#!/bin/bash

pids=`for i in $( cd /proc;ls |grep "^[0-9]"|awk ' $0 >100') ;do awk '/Swap:/{j=j+$2}END{print '"$i"',j/1024"M"}' /proc/$i/smaps 2>/dev/null ; done | sort -k2nr | head -10 | awk '{print $1}'`

for pid in ${pids}; do  ls -lt /proc/${pid}/cwd; done

for i in $( cd /proc;ls |grep "^[0-9]"|awk ' $0 >100') ;do awk '/Swap:/{j=j+$2}END{print '"$i"',j/1024"M"}' /proc/$i/smaps 2>/dev/null ; done | sort -k2nr | head -10
