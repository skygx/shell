#!/bin/bash
#set -ox

#vars=(192.168.226.20:81 192.168.226.20:82)
file="./servers.txt"
vars=$(cat ${file})
old_weight=99
new_weight=100

servers_in_file(){
count=$(wc -l $file|cut -d\  -f 1)
echo "$count servers in file."
}

count_server(){
for i in ${vars[@]}
do
count=$(grep -cn "$i" ./nginx.conf)
echo "hit ${i} server count ${count} times."
done
}

modify_weight(){
for i in ${vars[@]}
do
sed -i '/'''${i}'''/s/\(.*weight\)='''${old_weight}'''\(.*\)/\1='''${new_weight}'''\2/' ./nginx.conf
#sed -i '/'''${i}'''/s/weight=10;/weight=100;/' ./nginx.conf
echo "${i} server weight from  ${old_weight} to ${new_weight}."
done
}

down_server(){
for i in ${vars[@]}
do
sed -i '/'''${i}'''/s/\(.*\);/\1 down;/' ./nginx.conf
echo "${i} server is down. "
done

}

recover_down_server(){
for i in ${vars[@]}
do
sed -i '/'''${i}'''/s/\(.*\)down\(.*\)/\1 \2/' ./nginx.conf
echo "${i} server is recover. "
done
}

#down_server
#recover_down_server
#count_server
#modify_weight
servers_in_file
