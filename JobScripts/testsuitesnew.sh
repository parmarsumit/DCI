#!/bin/bash

moveTestFiles()
{
        server_ip=$1
	HOST_SSH_PORT=$2
	ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${HOST_SSH_PORT}  "ls /usr/share/nginx/www/ProgrammableWeb/tests/phpunit_tests | grep Test.php > /tmp/testfile"
}

countTestFiles()
{
        server_ip=$1
	HOST_SSH_PORT=$2
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${HOST_SSH_PORT} "cat /tmp/testfile | wc -l"
}

getNumberOfTestPerMachine()
{
        numberOfTest=$1
        numberOfInstance=$2
        expr $numberOfTest / $numberOfInstance
        
}

createTestSuiteFile()
{
numberOfTestSuite=$1
numberOfTestFile=$2
server_ip=$3
HOST_SSH_PORT=$4
	ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${HOST_SSH_PORT} "echo '<testsuites>' >> /usr/share/nginx/www/ProgrammableWeb/config.xml"
	range=`seq 1 ${numberOfTestSuite}`
	for x in $range; 
	do
		createTestSuite $x ${numberOfTestFile} ${server_ip}
	done
	 ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${HOST_SSH_PORT} "echo '</testsuites>' >> /usr/share/nginx/www/ProgrammableWeb/config.xml"
}

createTestSuite()
{
numberOfTestSuite=$1
numberOfTestFile=$2
server_ip=$3
HOST_SSH_PORT=$4
        n=`expr ${numberOfTestFile} - 1`
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${HOST_SSH_PORT} "head -${numberOfTestFile} /tmp/testfile > /tmp/file && sed -i "1,+${n}d" /tmp/testfile"
   	scp -o StrictHostKeyChecking=no -P ${HOST_SSH_PORT} root@${server_ip}:/tmp/file /tmp/file 
        ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${HOST_SSH_PORT} "echo '<testsuite name="\"SET${numberOfTestSuite}"\">' >> /usr/share/nginx/www/ProgrammableWeb/config.xml"
        while read line
        do
        	fileName=${line}
		     ssh -o StrictHostKeyChecking=no -n root@${server_ip} -p ${HOST_SSH_PORT} "echo '<file>tests/phpunit_tests/${fileName}</file>' >> /usr/share/nginx/www/ProgrammableWeb/config.xml"
        done < /tmp/file
	ssh root@${server_ip} -o StrictHostKeyChecking=no -p ${HOST_SSH_PORT} "echo '</testsuite>' >> /usr/share/nginx/www/ProgrammableWeb/config.xml"
}
