#!/bin/bash

moveTestFiles()
{
        server_ip=$1
	ssh root@${server_ip} -p 4940  "ls /usr/share/nginx/www/ProgrammableWeb/tests/phpunit_tests | grep Test.php > /tmp/testfile"
}

countTestFiles()
{
        server_ip=$1
        ssh root@${server_ip} -p 4940 "cat /tmp/testfile | wc -l"
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
	ssh root@${server_ip} -p 4940 "echo '<testsuites>' >> /usr/share/nginx/www/ProgrammableWeb/config.xml"
	range=`seq 1 ${numberOfTestSuite}`
	for x in $range; 
	do
		createTestSuite $x ${numberOfTestFile} ${server_ip}
	done
	 ssh root@${server_ip} -p 4940 "echo '</testsuites>' >> /usr/share/nginx/www/ProgrammableWeb/config.xml"
}

createTestSuite()
{
numberOfTestSuite=$1
numberOfTestFile=$2
server_ip=$3
        n=`expr ${numberOfTestFile} - 1`
        ssh root@${server_ip} -p 4940 "head -${numberOfTestFile} /tmp/testfile > /tmp/file && sed -i "1,+${n}d" /tmp/testfile"
   	scp -P 4940 root@${server_ip}:/tmp/file /tmp/file 
        ssh root@${server_ip} -p 4940 "echo '<testsuite name="\"SET${numberOfTestSuite}"\">' >> /usr/share/nginx/www/ProgrammableWeb/config.xml"
        while read line
        do
        	fileName=${line}
		     ssh -n root@${server_ip} -p 4940 "echo '<file>tests/phpunit_tests/${fileName}</file>' >> /usr/share/nginx/www/ProgrammableWeb/config.xml"
        done < /tmp/file
	ssh root@${server_ip} -p 4940 "echo '</testsuite>' >> /usr/share/nginx/www/ProgrammableWeb/config.xml"
}
