import boto3
import datetime
import json
import os
import re
import uuid

# es_alias = os.getenv('es_alias')
prefix = os.getenv('prefix')
clientRequestToken = "{}-{}".format(prefix, str(uuid.uuid4()))
cluster = {
    'dpl': {'develop': 'dpl-DemandPlatform-Test', 'master': ''},
    'fdh': {'develop': 'fdh-cluster-dev', 'master': 'fdh-fastlane'}
}
client_type = {False: 'codepipeline', True: 'ecs'}


def handler(event, context):
    print("incoming event:" + json.dumps(event))
    common = event['Records'][0]['Sns']
    timestamp = datetime.datetime.strptime(
        common['Timestamp'], '%Y-%m-%dT%H:%M:%S.%fZ').isoformat()
    m = json.loads(common['Message'])
    branch = m["detail"]["referenceName"]
    repo = m["detail"]["repositoryName"]
    project = repo[:3]
    contains_deploy = re.search("-deploy$", repo)
    is_specific_version_deploy = True if contains_deploy else False
    repo_arn = m["resources"][0]
    print("repo: {}({})\nbranch: {} \nat {}".format(
        repo, repo_arn, branch, timestamp))
    client_sts = boto3.client('sts')
    print("details user: {}".format(client_sts.get_caller_identity()))
    client = boto3.client('codecommit')
    tags = client.list_tags_for_resource(resourceArn=repo_arn)
    print("tags: {}".format(tags))
    deploy_version = tags['tags'].get('deploy_version', None)
    no_event_deploy = True if deploy_version is not None else False
    print("current deploy version: {} (is new deploy? {})".format(
        deploy_version, no_event_deploy))
    if no_event_deploy:
        print("doing new deploy")
        print("deploing in {}".format(branch))
        if branch == 'develop':
            sts_connection = boto3.client('sts')
            test_account = sts_connection.assume_role(
                RoleArn="arn:aws:iam::796341525871:role/dpl-admin-role", RoleSessionName="cross_acct_lambda")

            ACCESS_KEY = test_account['Credentials']['AccessKeyId']
            SECRET_KEY = test_account['Credentials']['SecretAccessKey']
            SESSION_TOKEN = test_account['Credentials']['SessionToken']
            test_client = boto3.client(
                client_type[is_specific_version_deploy],
                aws_access_key_id=ACCESS_KEY,
                aws_secret_access_key=SECRET_KEY,
                aws_session_token=SESSION_TOKEN,
            )
            if is_specific_version_deploy:
                service = re.search("(.*)-deploy", repo).group(1)
                print(
                    "cluster -->{} service -->{}".format(cluster[project][branch], service))
                response = test_client.list_task_definitions(
                    sort='DESC',
                    familyPrefix=service
                )
                print(json.dumps(response))
                tag_value = "796341525871.dkr.ecr.eu-west-1.amazonaws.com/dpl-mainfront-frontend-snapshot:v0.0.2"
                for arn in response['taskDefinitionArns']:
                    task_definition = re.search("\\/([^/]+)", arn).group(1)
                    describe = test_client.describe_task_definition(
                        taskDefinition=task_definition, include=[
                            'TAGS',
                        ])
                    print(json.dumps(describe))
                    found = True if tag_value in [
                        a['value'] for a in describe['tags']] else False
                    if found:
                        update_service = test_client.update_service(
                            cluster=cluster[project][branch],
                            service=service,
                            taskDefinition=task_definition
                        )
                        print("deploying {} with {}".format(
                            task_definition, tag_value))
                        print(update_service)
                        break
                    print("skipping {} because {} was not found".format(
                        task_definition, tag_value))
            else:
                response = test_client.start_pipeline_execution(
                    name=repo,
                    clientRequestToken=clientRequestToken
                )
            print(response)
        elif branch == 'master':
            prod_pipeline = boto3.client('codepipeline')
            response = prod_pipeline.start_pipeline_execution(
                name=repo_arn,
                clientRequestToken=clientRequestToken
            )
            print(response)
        else:
            print("???")
            print("branch {} not recognized skipping".format(branch))
            # skipping
    else:
        print("doing old deploy, skipping")
        # skipping

    # print("context:" + json.dumps(context))
    """
    clientRequestToken="{}-{}".format(prefix,str(uuid.uuid4()))
    response = client.start_pipeline_execution(
    name='string',
    clientRequestToken=clientRequestToken
    )


    """
    return event
