#!/bin/bash
source /var/lib/jenkins/JobScripts/jenkins_functions.sh
source /var/lib/jenkins/JobScripts/git_functions.sh
check_active_port(){
	RANGE_MIN=$1
	RANGE_MAX=$2
	port=`shuf -i $RANGE_MIN-$RANGE_MAX -n 1`
	while :
	do
		grep -wq $port /var/lib/jenkins/portlookup/portlookup.txt
		if [ $? -eq 0 ]
          	then
              		port=`shuf -i $RANGE_MIN-$RANGE_MAX -n 1`
          	else
              		break
          	fi
	done
	echo ${port}	
}

list_used_ports() {
	netstat -ant | awk '{ print $4}' | rev |cut -d ":" -f1|rev|uniq -u | grep -o '[0-9]*'>/var/lib/jenkins/portlookup/portlookup.txt
        [ -s /var/lib/jenkins/portlookup/portlookup.txt ]
        if [ $? -eq 1 ]; then
        	echo "10">>/var/lib/jenkins/portlookup/portlookup.txt
        fi
}

assign_ports(){
	serv_name=$1
	grep -wq $serv_name /var/lib/jenkins/portlookup/server_mapping
	if [ $? -eq 0 ]; then
		echo "This server name already exists."
		exit 1
	else
      		list_used_ports
		addsshport=`check_active_port 8000 8999` 
		addvncport=`check_active_port 7000 7999`
		addnginxport=`check_active_port 9000 9999`

		echo "$serv_name $addsshport $addvncport $addnginxport">>/var/lib/jenkins/portlookup/server_mapping
	fi
}

deleteServer() {
	server_name=$1
	grep -wq $server_name /var/lib/jenkins/portlookup/server_mapping
	if [ $? -eq 0 ]
	then
    		linenum=$(grep -nw $server_name /var/lib/jenkins/portlookup/server_mapping|sed 's/^\([0-9]\+\):.*$/\1/')
    		sed -i "${linenum}d" /var/lib/jenkins/portlookup/server_mapping
	else
    		echo "No server with this name"
		exit 1
	fi
}

getPort(){
	servername=$1
	find_port=$2
	port_value=$(grep -w $servername /var/lib/jenkins/portlookup/server_mapping | cut -d " " -f${find_port})
	echo $port_value
}

getSSHPort(){
	name=$1
	grep -wq $name /var/lib/jenkins/portlookup/server_mapping
	if [ $? -eq 0 ]
	then
		sshport=`getPort ${name} 2`
		echo $sshport
	else
		echo "This server does not exist"
		exit 1
	fi
}

getVNCPort(){
	name=$1
        grep -wq $name /var/lib/jenkins/portlookup/server_mapping
        if [ $? -eq 0 ]
        then
                vncport=`getPort ${name} 3`
		echo $vncport
        else
                echo "This server does not exist"
                exit 1
        fi
}

getNginxPort(){
        name=$1
        grep -wq $name /var/lib/jenkins/portlookup/server_mapping
        if [ $? -eq 0 ]
        then
                nginxport=`getPort ${name} 4`
                echo $nginxport
        else
                echo "This server does not exist"
                exit 1
        fi
}


mergeBranchToActiveBranches() {
	SOURCE_BRANCH=$1
	WORKING_DIR=$2

	TARGET_BRANCHES=`grep Server /var/lib/jenkins/portlookup/server_mapping | cut -d " " -f1`
	rm -f "/var/lib/jenkins/jobs/merge_master_to_feature/branchmerges"
	touch "/var/lib/jenkins/jobs/merge_master_to_feature/branchmerges"
	echo "EMAIL=" >> "/var/lib/jenkins/jobs/merge_master_to_feature/email.properties"
	for TARGET_BRANCH in ${TARGET_BRANCHES}; do
		TARGET_BRANCH=`echo ${TARGET_BRANCH/_Server}`
		build_merge merge_source_target ${SOURCE_BRANCH} ${TARGET_BRANCH} /var/lib/jenkins/workspace/merge_source_target 
	done
}

#I'll receive a git repo url, I'll check if there are any new branches created in this repo url, if so I'll run SetupFeatureBranch jenkins job to initiate the
# CI setup for each feature branch
check_for_new_branches() {
	GIT_REPO_URL=$1
	git ls-remote --heads ${GIT_REPO_URL} | cut -d/ -f3 | sort > /var/lib/jenkins/branch_changes/branch_list_latest
	comm -3 /var/lib/jenkins/branch_changes/branch_list /var/lib/jenkins/branch_changes/branch_list_latest | sed 's/^\t//' > /var/lib/jenkins/branch_changes/branches
	[ -s /var/lib/jenkins/branch_changes/branches ]
	if [ $? -eq 1 ]; then
#		mv /var/lib/jenkins/branch_changes/branch_list_latest /var/lib/jenkins/branch_changes/branch_list
		echo "No new branches created"
        else
		mv /var/lib/jenkins/branch_changes/branch_list_latest /var/lib/jenkins/branch_changes/branch_list
		while read -r branchName
		do
			echo "Running setup feature branch job for new branch ${branchName}"
			BRANCH_OWNER_EMAIL=$(get_branch_author_email $branchName)
			echo "BRANCH_OWNER_EMAIL=${BRANCH_OWNER_EMAIL}" > /var/lib/jenkins/branch_changes/branchOwner.email
			build_job SetupFeatureBranch ${branchName}
		done < /var/lib/jenkins/branch_changes/branches
	fi
}

check_branch() {
	branch=$1
	grep -Fx ${branch} /var/lib/jenkins/branch_changes/branch_list
	if [ $? -eq 0 ]
	then
		echo "Branch already exist"
		exit 1
	fi
}

setup_mysql() {
	server_ip=$1
        ssh_port=$2
	LOCAL_MYSQL_DATA_DIR=$3
	echo $server_ip  $ssh_port $JENKINS_HOME
	echo "Stop mysql service"
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "service mysql stop"
	echo "Copy database"
	time scp -r -o StrictHostKeyChecking=no -P ${ssh_port} ${LOCAL_MYSQL_DATA_DIR}/data/mysql root@${server_ip}:/var/lib
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "chown -R mysql:mysql /var/lib/mysql"
	echo "Copy my.cnf"
        scp -r -o StrictHostKeyChecking=no -P ${ssh_port} ${LOCAL_MYSQL_DATA_DIR}/data/my.cnf root@${server_ip}:/etc/mysql
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "chown -R root:root /etc/mysql/my.cnf"
	echo "Start mysql service"
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "service mysql start"
}

copy_files() {
	server_ip=$1
        ssh_port=$2
	CODE_FILES_DIR=$3
	echo "Copy files"
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "rm -rf /data/files"
        time scp -r -o StrictHostKeyChecking=no -P ${ssh_port} ${CODE_FILES_DIR}/data/files root@${server_ip}:/data/

        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "rm -rf /data/settings.php"
        scp -r -o StrictHostKeyChecking=no -P ${ssh_port} ${CODE_FILES_DIR}/data/settings.php root@${server_ip}:/data/

        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "chown -R www-data /data/files"
}


copy_git_project() {
	server_ip=$1
        ssh_port=$2
        source_dir=$3
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "mkdir -p /usr/share/nginx/www/ProgrammableWeb"
        scp -r -o StrictHostKeyChecking=no -P ${ssh_port} ${source_dir}/. root@${server_ip}:/usr/share/nginx/www/ProgrammableWeb/
}

change_settings() {
	server_ip=$1
        ssh_port=$2
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "cd /usr/share/nginx/www/ProgrammableWeb/sites/default && chown -R www-data:root files && chown root:root settings.php"
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "cd /usr/share/nginx/www/ProgrammableWeb/sites/default && chmod 644 settings.php"
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "cd /data && chown -R www-data:root files && chown root:root settings.php"
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${ssh_port} "cd /data && chmod 644 settings.php"
}

copy_setting_files() {
	server_ip=$1
        ssh_port=$2
	JENKINS_HOME=$3
        scp -o StrictHostKeyChecking=no -P ${ssh_port} ${JENKINS_HOME}/data/default root@${server_ip}:/etc/nginx/sites-available
        scp -o StrictHostKeyChecking=no -P ${ssh_port} ${JENKINS_HOME}/data/php.ini root@${server_ip}:/etc/php5/fpm/
        scp -o StrictHostKeyChecking=no -P ${ssh_port} ${JENKINS_HOME}/data/behat.yml root@${server_ip}:/usr/share/nginx/www/ProgrammableWeb/tests/
        scp -o StrictHostKeyChecking=no -P ${ssh_port} ${JENKINS_HOME}/data/composer.json root@${server_ip}:/usr/share/nginx/www/ProgrammableWeb/tests/
}

