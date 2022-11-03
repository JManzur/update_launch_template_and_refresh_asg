pipeline {
    agent any
    stages {
        stage('Build') {
          environment {
            FUNCTION_ARN = 'arn:aws:lambda:us-east-1:931366402038:function:Refresh-ASG-Lambda'
            }
            parallel {
                stage('Refresh') {
                    when {
                      expression { params.Action == "Refresh" }
                    }
                    steps {
                      withAWS(credentials: 'Caylent-Testing', region: 'us-east-1') {
                        sh '''
                              #!/bin/bash
                              set -x
                              ASG_Name=${AutoScalingGroupName}
                              aws lambda invoke --function-name ${FUNCTION_ARN} --cli-binary-format raw-in-base64-out --payload '{"Action": "Refresh","AutoScalingGroupName": "'"$ASG_Name"'"}' response.json | jq -r
                              cat response.json | jq -r
                          '''
                      }
                    }
                }
                stage('Refresh-With-New-AMI') {
                    when {
                      expression { params.Action == "Refresh-With-New-AMI" }
                    }
                  steps {
                    withAWS(credentials: 'Caylent-Testing', region: 'us-east-1') {
                      sh '''
                            #!/bin/bash
                            set -x
                            ASG_Name=${AutoScalingGroupName}
                            aws lambda invoke --function-name ${FUNCTION_ARN} --cli-binary-format raw-in-base64-out --payload '{"Action": "Refresh-With-New-AMI","AutoScalingGroupName": "'"$ASG_Name"'"}' response.json | jq -r
                            cat response.json | jq -r
                        '''
                    }
                  }
                }
            }
        }
    }
}