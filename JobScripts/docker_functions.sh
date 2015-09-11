#!/bin/bash
create_container(){
	container="${1}_Container"
	host_sshport=$2
	container_sshport=$3
	host_vncport=$4
	container_vncport=$5
	host_nginxport=$6
	container_nginxport=$7
	image_name=$8
	docker run -d --name $container -p ${host_sshport}:${container_sshport} -p ${host_vncport}:${container_vncport} -p ${host_nginxport}:${container_nginxport} ${image_name}
}

delete_container(){
	BRANCH_NAME=$1
	container="${BRANCH_NAME}_Container"
	docker rm -f -v $container
}

create_image_from_container() {

	BRANCH_NAME=$1
	CONTAINER_NAME="${1}_Container"
	IMAGE_NAME="${BRANCH_NAME}_IMAGE"

	docker commit ${CONTAINER_NAME} ${IMAGE_NAME,,}
}

create_image_dump() {
	BRANCH_NAME=$1
	DUMP_LOCATION=$2
	IMAGE_NAME="${BRANCH_NAME}_IMAGE"

	docker save ${IMAGE_NAME,,} > ${DUMP_LOCATION}/${IMAGE_NAME,,}.tar 
}	

delete_image() {
	BRANCH_NAME=$1
	DUMP_LOCATION=$2
	IMAGE_NAME="${BRANCH_NAME}_IMAGE"

	rm -f ${DUMP_LOCATION}/${IMAGE_NAME,,}.tar
	docker rmi ${IMAGE_NAME,,}
}

install_docker() {
        server_ip=$1
        ssh -o StrictHostKeyChecking=no root@${server_ip} "sudo apt-get update"
        ssh -o StrictHostKeyChecking=no root@${server_ip} "docker"
        if [ $? -eq 0 ]
        then
          echo "docker allredy installed"
        else
           echo "docker install"
           ssh -o StrictHostKeyChecking=no root@${server_ip} "curl -sSL https://get.docker.com/ | sh"
        fi
}

copy_docker_image(){
        DUMP_LOCATION=$1
	BRANCH_NAME=$2
        server_ip=$3
	IMAGE_NAME="${BRANCH_NAME}_IMAGE"

        time scp -r -o StrictHostKeyChecking=no ${DUMP_LOCATION}/${IMAGE_NAME,,}.tar root@${server_ip}:docker.tar
        echo "Load docker images"
        ssh -o StrictHostKeyChecking=no root@${server_ip} "docker load < ~/docker.tar"
#        ssh -o StrictHostKeyChecking=no root@${server_ip} "docker tag 89bd1c4685b3 vnc_php_test:latest"
}


