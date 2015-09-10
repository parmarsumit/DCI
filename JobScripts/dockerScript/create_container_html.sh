#!/bin/bash
source /var/lib/jenkins/JobScripts/jenkinsScript/jenkins_functions.sh
source /var/lib/jenkins/JobScripts/util_functions.sh

create_cell() {
	cellText=$1
	htmlFile=$2

	echo "Writing $cellText in $htmlFile"	
	echo "<td>" >> $htmlFile
	echo $cellText >> $htmlFile
	echo "</td>" >> $htmlFile
}

create_cell_from_file_content() {
        filePath=$1
        htmlFile=$2

	echo "writing below content in $htmlFile"
	cat $filePath

        echo "<td>" >> $htmlFile
        cat $filePath >> $htmlFile
	if [ "$?" == "1" ]; then
		echo "Not Available" >> $htmlFile
	fi
        echo "</td>" >> $htmlFile

}

create_cell_from_job_status() {
	jobName=$1
	echo $jobName
        html=$2
        jobStatus=`get_job_status $jobName`
	echo "Status of job $jobName is $jobStatus"
	echo "<td>" >> $htmlFile
        echo "<a href='${JENKINS_URL}job/${jobName}/'>${jobStatus}</a>" >> $htmlFile
        echo "</td>" >> $htmlFile
}

create_cell_from_multi_job_status() {
        jobName=$1
	echo $jobName
        html=$2
        jobStatus=`get_job_status_multijob $jobName`
	echo "<td>" >> $htmlFile
        echo "<a href='${JENKINS_URL}job/${jobName}/'>${jobStatus}</a>" >> $htmlFile
        echo "</td>" >> $htmlFile
}

create_execute_wrapper_job_button(){
	htmlFile=$1
	branch=$2
	echo "<td>" >> $htmlFile
	echo "<form method='post' action='${JENKINS_URL}job/${branch}MultiJob/build?delay=0sec'><input type='hidden' name='user' value='${USERNAME}:${PASSWORD}'/><input type='submit' value='Run tests' /></form>" >> $htmlFile
	echo "</td>" >> $htmlFile
}

create_container_html() {
filename=$1
path=$2

cat <<EOF >> $path
<html>
<head>
<title>
Server mappings info
</title></head>
<body>
<table width='100%' border='2'>
<tr>
<th> Server name </th><th> SSH Port </th><th> VNC Port </th><th> Web Server Port </th><th> Wrapper Code Quality Status </th><th> Merge Status </th><th> Unit Tests Status </th><th> Functional Test Status </th><th> Static Code Analysis Status </th></tr>
EOF

while read -r line
do
	name=$line
	echo "<tr>" >> $path
	create_cell `echo "$name" | cut -d " " -f1` $path

	create_cell `echo "$name" | cut -d " " -f2` $path

	create_cell `echo "$name" | cut -d " " -f3` $path

	create_cell `echo "$name" | cut -d " " -f4` $path

	current_server=`echo "$name" | cut -d " " -f1`
	current_branch=`echo ${current_server/_Server}`

	create_cell_from_multi_job_status "${current_branch}MultiJob" $path

	if [ ! -f "/var/lib/jenkins/jobs/${current_branch}MultiJob/mergestatus.txt" ]; then
                touch "/var/lib/jenkins/jobs/${current_branch}MultiJob/mergestatus.txt" 
		echo "NoMergesYet" >> "/var/lib/jenkins/jobs/${current_branch}MultiJob/mergestatus.txt"
        fi

	create_cell_from_file_content /var/lib/jenkins/jobs/${current_branch}MultiJob/mergestatus.txt $path

	create_cell_from_job_status "${current_branch}UnitTest" $path
	
	create_cell_from_job_status "${current_branch}FunctionalTest" $path
	
	create_cell_from_job_status "${current_branch}StaticCodeAnalysis" $path

	create_execute_wrapper_job_button $path ${current_branch}

	echo "</tr>" >> $path
done < "$filename"
echo "</table>" >> $path
echo "</body>" >> $path
echo "</html>" >> $path
}
