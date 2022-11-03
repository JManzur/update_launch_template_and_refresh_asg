#!/bin/bash

source_env () {
    set -e
    set -a
    source .env
}

refresh () {
    cd "$(dirname "$0")"
    source_env
    ASG_Name=$1
	aws lambda invoke --function-name $FUNCTION_ARN --cli-binary-format raw-in-base64-out --payload '{"Action": "Refresh","AutoScalingGroupName": "'"$ASG_Name"'"}' response.json --region $AWS_REGION --profile $AWS_PROFILE | jq -r
    cat response.json | jq -r
}

refresh_with_new_ami () {
    cd "$(dirname "$0")"
    source_env
    ASG_Name=$1
	aws lambda invoke --function-name $FUNCTION_ARN --cli-binary-format raw-in-base64-out --payload '{"Action": "Refresh-With-New-AMI","AutoScalingGroupName": "'"$ASG_Name"'"}' response.json --region $AWS_REGION --profile $AWS_PROFILE | jq -r
    cat response.json | jq -r
}

# Check if the command is installed
declare -A array=(
    [jq]="https://stedolan.github.io/jq/download/"
    [aws]="https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
)

for key in "${!array[@]}"; 
do
    if command -v $key > /dev/null
        then
            echo "" > /dev/null
        else
            echo "[ERROR] $key not installed - Please install $key to continue"
            echo -e '\n'
            echo "Ref: ${array[$key]}"
            echo -e '\n'
            exit 1
    fi
done

# Check parameters:
if [ $# -eq 0 ]
then
	echo "[ERROR] The AutoScalingGroupName variable is needed."
	exit 1
fi

PS3='Select the action to perform: '
OPTIONS=("Refresh" "Refresh-With-New-AMI" "Quit")
select opt in "${OPTIONS[@]}"
do
	case $opt in
		"Refresh")
            echo 'Executing action: Refresh'
			refresh
            exit 0
			;;
		"Refresh-With-New-AMI")
            echo 'Executing function: Refresh-With-New-AMI'
			refresh_with_new_ami
            exit 0
			;;
		"Quit")
			echo "Script ended"
			break
			;;
		*)
			echo "$REPLY is an invalid option"
			exit 1
			;;
	esac
done