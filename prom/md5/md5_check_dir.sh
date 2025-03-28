#!/bin/bash

Date=$(date +%Y%m%d%H%M%S)
dir="/root/shell_test/"

##	由于md5sum对大型文件需要耗费很长的时间，所以跳过大于50M的文件
find $dir -maxdepth 1 -type f -size -50M | while read filename
do
    md5sum $filename >> mymd5.$Date;
done

exit 0

