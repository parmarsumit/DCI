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
        else   
                echo "$new_instance_id"
        fi
}
