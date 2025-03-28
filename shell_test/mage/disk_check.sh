#!/bin/bash

WARNING=80
SPACE_USED=`df|grep '^/dev/sd'|tr -s ' ' %|cut -d% -f5|sort -nr|head -1`
SPACE_USED=`df -t xfs|tr -s ' ' %|cut -d% -f5|sort -nr|head -1`
[ "$SPACE_USED" -ge $WARNING ] && echo "disk used is $SPACE_USED,will be full"
