#!/bin/bash

#work_dir="/root/test/md5"
work_dir=$(pwd)
app_name=$(basename ${work_dir})
echo "$app_name"
jar_file="${app_name}.jar"
md5_file="md5.txt"

key=$(md5sum ${work_dir}/${jar_file} | awk '{print $1}' )

if grep -q $key ${md5_file}
then
    echo "yes"
else
    echo "no"
    exit 1
fi
