#!/bin/bash
 
for file in `cat domain.txt`
do
    for loop in `seq 1 30`
    do
        rs=`curl -o /dev/null -s -w %{http_code} $file`
        echo "$file result -> $rs"
 
        urlresponse=${file}" -> "${rs}
 
        if [ $rs -eq 200  ]; then
            urlresponse=$urlresponse"\n"
            break
        else
            urlresponse=$urlresponse" error\n"
        fi
 
        sleep 2
    done
    result=${result}${urlresponse}
done
 
echo -e "\n-------------------"
echo -e  $result