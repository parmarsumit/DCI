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
	container="${1}_Container"
	docker rm -f -v $container
}

create_image_from_container() {

	BRANCH_NAME=$1
	CONTAINER_NAME="${1}_Container"
	IMAGE_NAME="${1}_IMAGE"

	docker commit ${CONTAINER_NAME} ${IMAGE_NAME,,}
}

create_image_dump() {
	BRANCH_NAME=$1
	DUMP_LOCATION=$2
	IMAGE_NAME="${1}_IMAGE"

	docker save ${IMAGE_NAME,,} > ${DUMP_LOCATION}/${IMAGE_NAME,,}.tar 
}	
