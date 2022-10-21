import boto3
import logging, os
from datetime import datetime

ec2 = boto3.client('ec2')
autoscaling = boto3.client('autoscaling')

aws_account_id = os.environ.get('aws_account_id')
ami_platform = os.environ.get('ami_platform')
ami_name_regex = os.environ.get('ami_name_regex')
launch_template_id = os.environ.get('launch_template_id')

now = datetime.utcnow()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info('event: {}'.format(event))

    auto_scaling_group_name = event['AutoScalingGroupName']
    
    try:
        latest_golden_ami_id = describe_image(ami_platform, ami_name_regex, aws_account_id)
        current_ami_id_in_launch_template = describe_launch_template_version(launch_template_id)

        if latest_golden_ami_id == current_ami_id_in_launch_template:
            Message = 'Current image ID: {}, Latest Golden image ID: {}, No need to update the launch template.'.format(current_ami_id_in_launch_template, latest_golden_ami_id)
            logger.info(Message)
            return {
                'Message': Message
            }
    
        else:
            logger.info('Current image ID: {}, Latest Golden image ID: {}, The launch template will be updated.'.format(current_ami_id_in_launch_template, latest_golden_ami_id))
            update_launch_template(launch_template_id, latest_golden_ami_id)
            set_new_launch_template_version_as_default(launch_template_id)
            Message = 'Refreshing the Auto Scaling Group {} with the latest Golden AMI {}'.format(auto_scaling_group_name, latest_golden_ami_id)
            Refresh = refresh_auto_scaling_group(auto_scaling_group_name)
            return {
                'Message': Message,
                'InstanceRefreshId': Refresh
            }

    except Exception as error:
        logger.error(error)

        return {
            'statusCode': 400,
            'message': 'An error has occurred',
            'moreInfo': {
                'Lambda Request ID': '{}'.format(context.aws_request_id),
                'CloudWatch log stream name': '{}'.format(context.log_stream_name),
                'CloudWatch log group name': '{}'.format(context.log_group_name)
                }
            }

def describe_image(ami_platform, ami_name_regex, aws_account_id):
    if ami_platform == 'windows':
        response = ec2.describe_images(
            Filters=[
                {
                    'Name': 'name',
                    'Values': ['{}'.format(ami_name_regex)]
                },
                {
                    'Name': 'virtualization-type',
                    'Values': ['hvm']
                },
                {
                    'Name': 'root-device-type',
                    'Values': ['ebs']
                },
                {
                    'Name': 'platform',
                    'Values': ['windows']
                }
            ],
            Owners=['{}'.format(aws_account_id)],
            IncludeDeprecated=False,
        )

    else:
        response = ec2.describe_images(
            Filters=[
                {
                    'Name': 'name',
                    'Values': ['{}'.format(ami_name_regex)]
                },
                {
                    'Name': 'virtualization-type',
                    'Values': ['hvm']
                },
                {
                    'Name': 'root-device-type',
                    'Values': ['ebs']
                }
            ],
            Owners=['{}'.format(aws_account_id)],
            IncludeDeprecated=False,
        )

    sorted_amis = sorted(
        response['Images'],
        key=lambda i: i['CreationDate'],
        reverse=True
        )
    latest_golden_ami_id = sorted_amis[0]['ImageId']
    return latest_golden_ami_id

def describe_launch_template_version(launch_template_id):
    response = ec2.describe_launch_template_versions(
        LaunchTemplateId='{}'.format(launch_template_id),
        Filters=[
            {
                'Name': 'is-default-version',
                'Values': ['true']
            }
        ]
    )

    current_ami_id_in_launch_template = response['LaunchTemplateVersions'][0]['LaunchTemplateData']['ImageId']
    return current_ami_id_in_launch_template

def update_launch_template(launch_template_id, latest_golden_ami_id):
    current_date = now.strftime("%d-%m-%Y-%H%M%S")

    response = ec2.create_launch_template_version(
        LaunchTemplateId='{}'.format(launch_template_id),
        SourceVersion='$Latest',
        VersionDescription='Latest-AMI-{}'.format(current_date),
        LaunchTemplateData={
            'ImageId': '{}'.format(latest_golden_ami_id)
        }
    )
    VersionNumber = response['LaunchTemplateVersion']['VersionNumber']
    ImageId = response['LaunchTemplateVersion']['LaunchTemplateData']['ImageId']
    logger.info("New launch template created with version number of {} and AMI ID {}".format(VersionNumber, ImageId ))

def set_new_launch_template_version_as_default(launch_template_id):
    response = ec2.modify_launch_template(
        LaunchTemplateId='{}'.format(launch_template_id),
        DefaultVersion="$Latest"
    )
    DefaultVersionNumber = response['LaunchTemplate']['DefaultVersionNumber']

    logger.info("Version ID number {} has been set as default in the launch template {}".format(DefaultVersionNumber, launch_template_id))

def refresh_auto_scaling_group(auto_scaling_group_name):
    response = autoscaling.start_instance_refresh(
        AutoScalingGroupName='{}'.format(auto_scaling_group_name),
        Strategy='Rolling'
    )

    return response['InstanceRefreshId']