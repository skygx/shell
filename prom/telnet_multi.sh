#!/bin/sh

PORT=21
file="iplist.txt"
if [ ! -f "$file" ]; then
   echo "Error: file not found"
   exit 1
fi
 
while IFS= read -r line
do
#	result=$(echo -e "\n" | telnet $line $port <<<quit 2> /dev/null | grep "Connected" )
    if telnet $line $PORT <<< quit 2> /dev/null | grep -i 'Connected'; then
        echo "$line:$PORT is open"
    else
        echo "$line:$PORT is closed"
    fi

done < "$file"
#touch testsss
