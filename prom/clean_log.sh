#!/bin/bash

path=/root/test/tmp/tccs-server
[ ! -d $path ] && echo "$path is not exist" && exit 1

find "$path" -type f -mmin +1440 -ls
find "$path" -type d -empty -ls
#find $path -type f -mmin +1440 -delete
#find $path -type d -empty -delete
