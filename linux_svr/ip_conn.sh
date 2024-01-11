
#!/bin/bash
# This script checks the number of connections per IP address
# and displays the IP addresses with more than a specified number of connections

# Set the maximum number of connections per IP address
# MAX_CONNECTIONS=50

# # Get the IP addresses and number of connections
# IP_COUNTS=$(netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr)

# # Loop through the IP addresses and number of connections
# while read -r COUNT IP; do
#   # If the number of connections is greater than the maximum, display the IP address and number of connections
#   if [[ "$COUNT" -gt "$MAX_CONNECTIONS" ]]; then
#     echo "$COUNT connections from $IP"
#   fi
# done <<< "$IP_COUNTS"

# The above code should fulfill the requirements of the prompt "shell脚本 检查ip连接数"

min=15000
max=20000

ip_conns=$(netstat -ant | grep EST | wc -l)
messages=$(netstat -ant | awk '/^tcp/ {++S[$NF]} END{for (a in S) print a,S[a]}' | tr -s '\n' ',' | sed -r 's/(.*),/\1\n/g')

if [ $ip_conns -lt $min ]; then
    echo "$messages, OK -connect counts is $ip_conns"
    exit 0
fi
if [ $ip_conns -gt $min -a $ip_conns -lt $max]; then
    echo "$messages, Warning -connect counts is $ip_conns"
    exit 1
fi
if [ $ip_conns -gt $max ]; then
    echo "$messages, Critical -connect counts is $ip_conns"
    exit 2
fi
