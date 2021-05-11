import boto3
import datetime
import json
import os
import re
import uuid

cluster_dev = os.getenv('cluster_dev')
cluster_prod = os.getenv('cluster_prod')
test_role_arn = os.getenv('test_role_arn')
prefix = os.getenv('prefix')
cluster = {
    'develop': cluster_dev, 'master': cluster_prod}
client_type = {False: 'codepipeline', True: 'ecs'}
message_id_cache = {}


def get_token():
    return "{}-{}".format(prefix, str(uuid.uuid4()))


def handler(event, context):
    print("incoming event:" + json.dumps(event))
    common = event['Records'][0]['Sns']
    timestamp = datetime.datetime.strptime(
        common['Timestamp'], '%Y-%m-%dT%H:%M:%S.%fZ').isoformat()
    message_id = common['MessageId']
    # avoid processing duplicated request (sns can send duplicated https://cloudonaut.io/your-lambda-function-might-execute-twice-deal-with-it/)
    # global variables in python are maintained between invocations if lambda is not recreated by AWS (so it's not accurately unique)
    if message_id_cache.get(message_id, None):
        print("event with MessageId: {} already processed".format(message_id))
        return
    else:
        message_id_cache[message_id] = '1'
    m = json.loads(common['Message'])
    branch = m["detail"]["referenceName"]
    repo = m["detail"]["repositoryName"]
    project = repo[:3]
    contains_deploy = re.search("-deploy$", repo)
    is_specific_version_deploy = True if contains_deploy else False
    repo_arn = m["resources"][0]
    print("repo: {}\nbranch: {} at {}".format(
        repo, branch, timestamp))
    client_cc = boto3.client('codecommit')
    tags = client_cc.list_tags_for_resource(resourceArn=repo_arn)
    deploy_version = tags['tags'].get('deploy_version', None)
    no_event_deploy = True if deploy_version is not None else False
    print("current deploy version: {} (is new deploy? {})".format(
        deploy_version, no_event_deploy))
    if no_event_deploy:
        no_event(branch, is_specific_version_deploy,
                 repo, project, client_cc, repo_arn)
    else:
        print("type: old deploy, skipping")
        # skipping

    return event


def no_event(branch, is_specific_version_deploy, repo, project, client_cc, repo_arn):
    print("type: new deploy")
    print("deploying on: {}".format(branch))
    sts_connection = boto3.client('sts')
    if branch == 'develop':
        test_account = sts_connection.assume_role(
            RoleArn=test_role_arn, RoleSessionName="cross_acct_lambda")

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
            response = deploy(repo, project, branch,
                              test_client, client_cc)
        else:
            response = build_n_deploy(test_client, repo)
        print(response)
    elif branch == 'master':
        if is_specific_version_deploy:
            response = deploy(repo, project, branch,
                              boto3.client('ecs'), client_cc)
        else:
            response = build_n_deploy(boto3.client('codepipeline'), repo)
        print(response)
    else:
        print("???")
        print("branch {} not recognized skipping".format(branch))


def build_n_deploy(client, repo):
    response = client.start_pipeline_execution(
        name=repo,
        clientRequestToken=get_token()
    )
    return response


def deploy(repo, project, branch, client, client_cc):
    service = re.search("(.*)-deploy", repo).group(1)
    print(
        "cluster -->{} service -->{}".format(cluster[branch], service))
    response = client.list_task_definitions(
        sort='DESC',
        familyPrefix=service
    )
    print(json.dumps(response))
    image_definition_byte = client_cc.get_file(
        repositoryName=repo, filePath='imagedefinitions.json', commitSpecifier=branch)['fileContent']
    print(json.loads(image_definition_byte))
    image_definitions = json.loads(image_definition_byte)
    tag_value = [x['imageUri']
                 for x in image_definitions if x['name'] == 'app'][0]
    print(tag_value)
    for arn in response['taskDefinitionArns']:
        task_definition = re.search("\\/([^/]+)", arn).group(1)
        describe = client.describe_task_definition(
            taskDefinition=task_definition, include=[
                'TAGS',
            ])
        print(describe)
        found = True if tag_value in [
            a['value'] for a in describe['tags']] else False
        if found:
            update_service = client.update_service(
                cluster=cluster[branch],
                service=service,
                taskDefinition=task_definition
            )
            print("deploying {} with {}".format(
                task_definition, tag_value))
            return update_service
            break
        print("skipping {} because {} was not found".format(
            task_definition, tag_value))
    # why this is not displayed?
    return "[ERROR] {} never found in any task definition".format(tag_value)
