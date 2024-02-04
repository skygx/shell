#!/bin/bash

work_dir=$(pwd)
#work_dir="/root/test/md5"
pro_name=$(basename ${work_dir})
jar_file="${pro_name}.jar"
md5_file="data.md5"

cd ${work_dir}

key=$( md5sum ${jar_file} | awk '{print $1}' )

if grep -q $key ${md5_file}
then
    echo "match"
else
    echo "no match"
    exit 1
fi
