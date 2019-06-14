import json
import boto3
import noaa_ftp
import filename_log

def lambda_handler(event, context):
    print("howMuchSnowDoUpdate")

    ftp = noaa_ftp.connect_to_ftp()
    newest_available = noaa_ftp.get_latest_run_filename(ftp)
    ftp.close()
    most_recent_import = filename_log.get_most_recent_filename()

    if most_recent_import == newest_available:
        print("Already imported:", newest_available)
    else:
        print("New file available")
        client = boto3.client('ecs')
        response = client.run_task(
            cluster='HowMuchSnow',
            taskDefinition='HowMuchSnow:2',
            count=1,
            launchType='FARGATE',
            networkConfiguration={
                'awsvpcConfiguration': {
                    'subnets': [
                        'subnet-ebce7c8c',
                    ],
                    'securityGroups': [
                        'sg-03bb63bf7b3389d42',
                    ],
                    'assignPublicIp': 'DISABLED'
                }
            },
        )
