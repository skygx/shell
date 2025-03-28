#!/bin/bash

CONSUL_TOKEN="<your_token_here>"
CONSUL_URL="http://192.168.226.20:8500"

register_service(){
  curl \
    --request PUT \
    --header "Content-Type: application/json" \
    --data "@- ${CONSUL_URL}/v1/agent/service/register" <<EOF
{
  "ID": "${1}",
  "Name": "${2}",
  "Address": "${3}",
  "Port": ${4}
}
EOF
}

deregister_service(){
  curl \
    --request PUT \
    --header "X-Consul-Token: ${CONSUL_TOKEN}" \
    "${CONSUL_URL}/v1/agent/service/deregister/${1}"
}

# example usage
#    --header "X-Consul-Token: ${CONSUL_TOKEN}" \
register_service "my-service" "My Service" "192.168.226.20" 80
#deregister_service "my-service"