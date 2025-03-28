#!/bin/bash

DATE=$(date +%Y%m%d)
#cp /etc/hosts /tmp/hosts.${DATE}
cp /etc/hosts /tmp/hosts.bak
key="xguo.com"
host_file="/etc/hosts"
if grep -q ${key} ${host_file}
then
  echo "${key} is exists"
  exit 0
else
  echo "${key} is not exists"
  echo "192.168.226.20  ${key}" >> ${host_file}
fi
