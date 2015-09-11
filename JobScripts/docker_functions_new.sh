#!/bin/bash
install_docker() {
	server_ip=$1
	ssh -o StrictHostKeyChecking=no root@${server_ip} "sudo apt-get update"
        ssh -o StrictHostKeyChecking=no root@${server_ip} "docker"  
	if [ $? -eq 0 ]
	then
	  echo "docker allredy install"
	else
	   echo "docker install"
	   ssh -o StrictHostKeyChecking=no root@${server_ip} "curl -sSL https://get.docker.com/ | sh"
	fi
}

copy_docker_image(){
	JENKINS_HOME=$1
	server_ip=$2
	time scp -r -o StrictHostKeyChecking=no ${JENKINS_HOME}/docker.tar root@${server_ip}:~/.
        echo "Load docker images"
	ssh -o StrictHostKeyChecking=no root@${server_ip} "docker load < ~/docker.tar"
	ssh -o StrictHostKeyChecking=no root@${server_ip} " docker tag 89bd1c4685b3 vnc_php_test:latest"
}
 
