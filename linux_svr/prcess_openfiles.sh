
#!/bin/bash
# This script checks the maximum number of files a process can open
# It takes a process ID as an argument


max_open_files=$(cat /proc/sys/fs/file-max)

# if [ -z "$pid" ]; then
#   echo "Please provide a process ID"
#   exit 1
# fi

# if [ ! -d "/proc/$pid" ]; then
#   echo "Process $pid not found"
#   exit 1
# fi
process_name=nginx

for pid in $(ps aux | grep ${process_name} | grep -v grep | awk '{print $2}')
do
    process_max_open_files=$(cat /proc/$pid/limits | grep "Max open files" | awk '{print $5}')

echo "Maximum number of files a process ${process_name} can open: $process_max_open_files"
echo "Maximum number of open files for the entire system: $max_open_files"
done


