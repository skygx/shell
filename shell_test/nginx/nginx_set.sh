#!/bin/bash

part1_file='part1.txt'
part2_file='part2.txt'


checkInt(){
expr $1 + 0 &> /dev/null
#if [[ $num =~ ^[1-9][0-9]*$ ]] 
if [ $? -eq 0 ] 
then
return 0
else
echo "Args must be integer!"
exit 1
fi 
}

create_server(){
curl -iX POST -d '{"server":"192.168.226.20:81","weight":"10","max_conns":"150","max_fails":"3","fail_timeout":"30s"}' http://192.168.226.20:88/api/1/http/upstreams/bk_svr/servers
curl -iX POST -d '{"server":"192.168.226.20:82","weight":"10","max_conns":"150","max_fails":"3","fail_timeout":"30s"}' http://192.168.226.20:88/api/1/http/upstreams/bk_svr/servers
curl -iX POST -d '{"server":"192.168.226.20:83","weight":"10","max_conns":"150","max_fails":"3","fail_timeout":"30s"}' http://192.168.226.20:88/api/1/http/upstreams/bk_svr/servers
curl -iX POST -d '{"server":"192.168.226.20:84","weight":"10","max_conns":"150","max_fails":"3","fail_timeout":"30s"}' http://192.168.226.20:88/api/1/http/upstreams/bk_svr/servers
}

part1(){
weight=$1
checkInt $weight
if [ $? -eq 0 ] 
then
i=0
while read row
do
echo $row
curl -isSX PATCH -o /dev/null -d '{
   "server":"'$row'",
   "weight":"'$weight'",
   "max_conns":"350",
   "max_fails": 3,
   "fail_timeout": "10s",
   "slow_start": "10s",
   "backup": false,
   "down": false
}' http://192.168.226.20:88/api/1/http/upstreams/bk_svr/servers/$i
((i += 1))
done < $part1_file
fi
}

part2(){
weight=$1
checkInt $weight
if [ $? -eq 0 ] 
then
i=2
while read row
do
echo $row
curl -isSX PATCH -o /dev/null -d '{
   "server":"'$row'",
   "weight":"'$weight'",
   "max_conns":"350",
   "max_fails": 3,
   "fail_timeout": "10s",
   "slow_start": "10s",
   "backup": false,
   "down": false
}' http://192.168.226.20:88/api/1/http/upstreams/bk_svr/servers/$i
((i += 1))
done < $part2_file
fi
}

down_server(){

curl -X PATCH -d '{\
 "down": true \ 
}' -s 'http://192.168.226.20:88/api/1/http/upstreams/bk_svr/servers/0'

}

part1 15
part2 30
#create_server
#curl -s http://192.168.226.20:88/api/1/http/upstreams/bk_svr/servers | jq
