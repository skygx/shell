#!/bin/bash

#CONSUL_TOKEN="<your_token_here>"
CONSUL_URL="http://192.168.226.20:8500"

register_service(){
url="${CONSUL_URL}/v1/agent/service/register"
#data='{"name": "nginx", "id": "nginx", "address": "192.168.226.20", "port": "80","tags": ["nginx"], "checks": [{"http": "http://192.168.226.20:80/", "interval": "5s"}]}'
#curl -X PUT -H 'Content-Type: application/json' -d {"name": "nginx", "id": "nginx", "address": "192.168.226.20", "port": "80","tags": ["nginx"], "checks": [{"http": "http://192.168.226.20:80/", "interval": "5s"}]} $url
#curl -X PUT -H 'Content-Type: application/json' -d '{"name": "nginx", "id": "nginx", "address": "192.168.226.20", "port": 80}' $url
curl -X PUT -H 'Content-Type: application/json' -d @ccc.json $url
#curl -X PUT -H 'Content-Type: application/json' -d @redis.json $url
}

deregister_service(){
url="${CONSUL_URL}/v1/agent/service/deregister/nginx"
curl -X PUT "$url"
}

# example usage
#    --header "X-Consul-Token: ${CONSUL_TOKEN}" \
#register_service "nginx" "nginx" "192.168.226.20" 80
register_service
#deregister_service "nginx"
