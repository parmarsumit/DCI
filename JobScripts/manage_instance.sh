createServerIfNotExist(){
        branch_name=$1
        file_name=$2
        SERVER_NAME=$3
        IMAGE=$4
        SIZE=$5
        ENDPOINT=$6 
        TOKEN=$7
        REGION=$8
        SSH_ID=$9
        new_instance_id=`cat ${file_name} | grep -w ${branch_name} | cut -d ' ' -f3`
    
        if [ "instance_id" == $new_instance_id ] 
        then
    		python ~/JobScripts/manage_instance.py 'launch_instance("'"$SERVER_NAME"'","'"$IMAGE"'","'"$SIZE"'","'"$ENDPOINT"'","'"$TOKEN"'","'"$REGION"'","'"$SSH_ID"'")'
		sleep 3m
        else   
                echo "$new_instance_id"
        fi
}


launchMultipleInstance(){
no_of_ins=$1
branch_name=$2
IMAGE=$3
SIZE=$4
ENDPOINT=$5
TOKEN=$6
REGION=$7
SSH_ID=$8
JENKINS_HOME=$9
NO_OF_INSTANCES=${10}

  echo "Lunching ${no_of_ins} instance.."
  GENERATED_SERVER_NAME="${branch_name}$RANDOM"
  instance_id=`python ${JENKINS_HOME}/JobScripts/manage_instance.py 'launch_instance("'"${GENERATED_SERVER_NAME}"'","'"${IMAGE}"'","'"${SIZE}"'","'"${ENDPOINT}"'","'"${TOKEN}"'","'"$REGION"'","'"$SSH_ID"'")'`
  echo "Waiting for instance to be built.."
  sleep 5m
 echo "Fetching instance fqdn.."
  server_ip=`python ${JENKINS_HOME}/JobScripts/manage_instance.py 'get_server_ip("'"$ENDPOINT"'","'"$TOKEN"'","'"$instance_id"'")'`

HOST_SSH_PORT=4940

echo "Installing Docker.."

install_docker ${server_ip}

echo "pull Docker Image.."
pullImagefroms3 ${branch_name} ${server_ip}

sleep 1m

echo "Creating container.."
create_container_at_server "${BRANCH_NAME}" 4940 22 5901 5901 8292 80 ${server_ip}

ssh root@${server_ip} -p ${HOST_SSH_PORT} "rm -rf /usr/share/nginx/www/ProgrammableWeb"

echo "Copying code.";
copy_git_project ${server_ip} ${HOST_SSH_PORT} ${WORKSPACE}

echo "Linking to files and settings already present on the container.";

ssh root@${server_ip} -p ${HOST_SSH_PORT} "ln -s /var/data/files /usr/share/nginx/www/ProgrammableWeb/sites/default/files";
ssh root@${server_ip} -p ${HOST_SSH_PORT} "chown -R www-data /usr/share/nginx/www/ProgrammableWeb/sites/default/files";
ssh root@${server_ip} -p ${HOST_SSH_PORT} "ln -s /var/data/settings.php /usr/share/nginx/www/ProgrammableWeb/sites/default/settings.php";

change_settings ${server_ip} ${HOST_SSH_PORT} 

copy_setting_files ${server_ip} ${HOST_SSH_PORT} ${JENKINS_HOME}

ssh root@${server_ip} -p ${HOST_SSH_PORT} "service php5-fpm restart"
serviceNginxRestart ${server_ip} ${HOST_SSH_PORT}

ssh root@${server_ip} -p ${HOST_SSH_PORT} "cd /usr/share/nginx/www/ProgrammableWeb/sites && drush cc all"

ssh root@${server_ip} -p ${HOST_SSH_PORT} "cd /usr/share/nginx/www/ProgrammableWeb/tests && rm -rf vendor"

ssh root@${server_ip} -p ${HOST_SSH_PORT} "cd /usr/share/nginx/www/ProgrammableWeb/tests && php composer.phar self-update"

ssh root@${server_ip} -p ${HOST_SSH_PORT} "cd /usr/share/nginx/www/ProgrammableWeb/tests && php composer.phar update"
ssh root@${server_ip} -p 4940 "cd /usr/share/nginx/www/ProgrammableWeb/results && rm -f *.xml"

moveTestFiles ${server_ip}

numberOfTest=`countTestFiles ${server_ip}`

numberOfTestFile=`getNumberOfTestPerMachine ${numberOfTest} ${NO_OF_INSTANCES}`

createTestSuiteFile ${NO_OF_INSTANCES} ${numberOfTestFile} ${server_ip}

ssh root@${server_ip} -p 4940 "cd /usr/share/nginx/www/ProgrammableWeb && tests/bin/phpunit -v --debug --stop-on-failure --configuration config.xml --testsuite SET${no_of_ins} --log-junit results/phpunit${no_of_ins}.xml"

scp -P 4940 root@${server_ip}:/usr/share/nginx/www/ProgrammableWeb/results/*.xml results/
echo "${GENERATED_SERVER_NAME} ${instance_id} ${server_ip}"  >> ${JENKINS_HOME}/portlookup/${branch_name}new_server_info
}

deleteMultipleInstance(){
JENKINS_HOME=$1
branch_name=$2
ENDPOINT=$3
TOKEN=$4
	rm -rf /tmp/${branch_name}instance_id 
	cat ${JENKINS_HOME}/portlookup/${branch_name}new_server_info |cut -d ' ' -f2 > /tmp/${branch_name}instance_id	
	while read line
	do
	instance_id=${line}
	echo "Delete instance"
		python ~/JobScripts/manage_instance.py 'del_instance("'"$ENDPOINT"'","'"$TOKEN"'","'"$instance_id"'")'
	done < /tmp/${branch_name}instance_id 
	rm -rf ${JENKINS_HOME}/portlookup/${branch_name}new_server_info

}





