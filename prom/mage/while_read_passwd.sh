#!/bin/bash
while read line ; do
if [[ $line =~ "/sbin/nologin" ]]; then
echo $line | cut -d: -f1,3
fi
done < /etc/passwd
