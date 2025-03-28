#!/bin/sh
 
# 使用 date计算工作日
# 参数1：起始日期，格式YYYY-MM-DD
# 参数2：结束日期，格式YYYY-MM-DD
 
# 检查参数个数
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 start_date end_date"
    exit 1
fi
 
# 起始和结束日期
start_date=$1
end_date=$2
 
# 计算工作日
#workdays=$( date -d "$start_date +1day" +%s)
workdays=0
while [ "$( date -d "$start_date +1day" +%s)" -le "$( date -d "$end_date" +%s)" ]; do
    # 检查是否为工作日（周一到周五）
    weekday=$( date -d "$start_date +1day" +%u)
    if [ "$weekday" -ge 1 ] && [ "$weekday" -le 5 ]; then
        workdays=$((workdays + 1))
    fi
    start_date=$( date -d "$start_date +1day" +%Y-%m-%d)
done

echo "Workdays between $1 and $2: $workdays"
