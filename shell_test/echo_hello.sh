#!/bin/bash
start_time=`date "+%s.%N"`
for ((i=0;i<5;i++));do
{
sleep 3
echo "hello,world" >> aa && echo "done!"
}&
done 
wait
cat aa|wc -l
rm aa
end_time=$(date +%s.%N)
diff_time=$(echo "$end_time - $start_time"|bc)
printf "It took %.6f seconds\n" $diff_time 

timenew=`LC_ALL="C" date +%d/%b/%G`
timebefore=`date --date='5 minutes ago' +%H:%M:%S`
nowtime=$(date +%H:%M:%S)
timebefore_awk=[$timenew:$timebefore
nowtime_awk=[$timenew:$nowtime
printf "timebefore: %s  \nnowtime: %s" $timebefore_awk $nowtime_awk
