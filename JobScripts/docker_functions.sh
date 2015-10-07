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

create_container_at_server(){

	BRANCH_NAME=$1
        container="${BRANCH_NAME}_Container"
        host_sshport=$2
        container_sshport=$3
        host_vncport=$4
        container_vncport=$5
        host_nginxport=$6
        container_nginxport=$7
        image_name="${BRANCH_NAME}_IMAGE"
	server_ip=$8
	ssh -o StrictHostKeyChecking=no root@${server_ip} "docker ps | grep -wq ${container}"
	if [ $? -eq 0 ]
        then
          echo "Container Already up"
       	else
          ssh -o StrictHostKeyChecking=no root@${server_ip} "docker run  -d --name $container -p ${host_sshport}:${container_sshport} -p ${host_vncport}:${container_vncport} -p ${host_nginxport}:${container_nginxport} ${image_name,,} /bin/sh -c "'"/bin/sh -c bash -C /usr/local/etc/spawn-desktop.sh && /etc/init.d/memcached start && /etc/init.d/mysql start && /etc/init.d/php5-fpm start && /etc/init.d/nginx start && /etc/init.d/jetty start && /usr/sbin/sshd -D && tailf /var/log/lastlog"'"" >/dev/null 2>&1
	  sleep 3m
	  ssh -o StrictHostKeyChecking=no root@${server_ip} -p ${host_sshport} "rm -rf /tmp/.*;/usr/local/etc/spawn-desktop.sh" >/dev/null 2>&1
	fi
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

       time docker commit ${CONTAINER_NAME} ${IMAGE_NAME,,}
}

create_image_dump() {
	BRANCH_NAME=$1
	DUMP_LOCATION=$2
	IMAGE_NAME="${BRANCH_NAME}_IMAGE"

	time docker save ${IMAGE_NAME,,} > ${DUMP_LOCATION}/${IMAGE_NAME,,}.tar 
}	

delete_image() {
	BRANCH_NAME=$1
#	DUMP_LOCATION=$2
	IMAGE_NAME="${BRANCH_NAME}_IMAGE"

	docker rmi ${IMAGE_NAME,,}
}

delete_image_dump() {
	BRANCH_NAME=$1
        DUMP_LOCATION=$2
        IMAGE_NAME="${BRANCH_NAME}_IMAGE"

        rm -f ${DUMP_LOCATION}/${IMAGE_NAME,,}.tar
}

install_docker() {
        server_ip=$1
        ssh -o StrictHostKeyChecking=no root@${server_ip} "docker" >/dev/null 2>&1
        if [ $? -eq 0 ]
        then
          echo "Docker Already Installed"
        else
           ssh -o StrictHostKeyChecking=no root@${server_ip} "curl -sSL https://get.docker.com/ | sh"
        fi
}

copy_docker_image(){

        DUMP_LOCATION=$1
	BRANCH_NAME=$2
        server_ip=$3
	IMAGE_NAME="${BRANCH_NAME}_IMAGE"
        ssh -o StrictHostKeyChecking=no root@${server_ip} "docker images | grep -q ${IMAGE_NAME,,}"
	if [ $? -eq 0 ];
	then
		echo "Image Already Exist .."
	else
        	time scp -r -o StrictHostKeyChecking=no ${DUMP_LOCATION}/${IMAGE_NAME,,}.tar root@${server_ip}:docker.tar
        	echo "Loading Docker Images .."
        	ssh -o StrictHostKeyChecking=no root@${server_ip} "docker load < ~/docker.tar"
		sleep 1m
	fi
}
