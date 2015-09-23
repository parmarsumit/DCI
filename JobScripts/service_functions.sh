#!/bin/bash

serviceNginxRestart(){
server_ip=$1
HOST_SSH_PORT=$2

ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${HOST_SSH_PORT} "ps -e| grep 'nginx' | awk '{print "'$1'"}'|xargs kill"
ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${HOST_SSH_PORT} "service nginx restart"
}
