#!/bin/bash

source_env () {
    set -e
    set -a
    source .env
}

source_env
# Check parameters:
if [ $# -eq 0 ]
then
	echo "[ERROR] The AutoScalingGroupName variable is needed."
	exit 1
fi

cd "$(dirname "$0")"
ASG_Name=$1
aws lambda invoke --function-name $FUNCTION_ARN --cli-binary-format raw-in-base64-out --payload '{"AutoScalingGroupName": "'"$ASG_Name"'"}' response.json --region $AWS_REGION --profile $AWS_PROFILE | jq -r
cat response.json | jq -r