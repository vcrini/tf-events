import boto3
import datetime
import json
import os
import uuid

# es_alias = os.getenv('es_alias')
prefix = os.getenv('prefix')
clientRequestToken = "{}-{}".format(prefix, str(uuid.uuid4()))


def handler(event, context):
    print("incoming event:" + json.dumps(event))
    common = event['Records'][0]['Sns']
    timestamp = datetime.datetime.strptime(
        common['Timestamp'], '%Y-%m-%dT%H:%M:%S.%fZ').isoformat()
    m = json.loads(common['Message'])
    branch = m["detail"]["referenceName"]
    repo = m["detail"]["repositoryName"]
    repo_arn = m["resources"][0]
    print("repo: {}({})\nbranch: {} \nat {}".format(
        repo, repo_arn, branch, timestamp))
    client_sts = boto3.client('sts')
    print("details user: {}".format(client_sts.get_caller_identity()))
    # lambda_client = boto3.client('lambda')
    # role_response = (lambda_client.get_function_configuration(
    #     FunctionName=os.environ['AWS_LAMBDA_FUNCTION_NAME']))
    # print(role_response)
    client = boto3.client('codecommit')
    tags = client.list_tags_for_resource(resourceArn=repo_arn)
    print("tags: {}".format(tags))
    deploy_version = tags['tags'].get('deploy_version', None)
    no_event_deploy = True if deploy_version is not None else False
    print("current deploy version: {}(is new deploy? {})".format(
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

            # create service client using the assumed role credentials, e.g. S3
            test_pipeline = boto3.client(
                'codepipeline',
                aws_access_key_id=ACCESS_KEY,
                aws_secret_access_key=SECRET_KEY,
                aws_session_token=SESSION_TOKEN,
            )
            response = test_pipeline.start_pipeline_execution(
                name=repo,
                clientRequestToken=clientRequestToken
            )
            print("response")
            print(response)
            print("/response")
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
