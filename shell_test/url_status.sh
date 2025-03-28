#!/usr/bin/env bash
# Create Date: 2022/2/15 下午 12:19
# Author:      hello
# Mail:        guoxin_well@126.com
# Version:     1.0
# Attention:   url_status.sh
set -eu

URL_LIST="www.baidu.com www.ctnrs.com www.der-matech.net.cn www.der-matech.com.cn www.der-matech.cn www.der-matech.top www.der-matech.org"
for URL in $URL_LIST; do
    FAIL_COUNT=0
    for ((i=1;i<=3;i++)); do
        HTTP_CODE=$(curl -o /dev/null --connect-timeout 3 -s -w "%{http_code}" $URL)
        if [ $HTTP_CODE -eq 200 ]; then
            echo "$URL OK"
            break
        else
            echo "$URL retry $FAIL_COUNT"
            let FAIL_COUNT++
        fi
    done
    if [ $FAIL_COUNT -eq 3 ]; then
        echo "Warning: $URL Access failure!"
  echo "网站${URL}坏掉，请及时处理" | mail -s "${URL}网站高危" sweet_love2000@126.com
    fi
done
