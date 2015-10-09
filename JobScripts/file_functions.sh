function getLineNoMatchingRegex() {
	local FILE_NAME="$1"
	local PATTERN="$2"

	echo `grep -i -n -w "$PATTERN" "$FILE_NAME" | awk '{print $1}' | cut -d':' -f1`
}


function updateColumn(){
	fileName=$1
	lineNumber=$2
	columnNumber=$3
	newValue=$4

	awk 'NR==lineNumber{$columnNumber=newValue}1' columnNumber=$columnNumber lineNumber=$lineNumber newValue=$newValue $fileName > tmp && mv tmp $fileName
}

function updateInstanceNumber()
{
        instanceNumber=$1
        JENKINS_HOME=$2
        sed -i -re 's/(NO_OF_INSTANCES=)[^=]*$/\1'$instanceNumber'/' ${JENKINS_HOME}/JobScripts/jenkins.properties
}

