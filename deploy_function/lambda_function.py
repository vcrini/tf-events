import json
import os
import uuid

# es_alias = os.getenv('es_alias')
prefix = os.getenv('prefix')


def handler(event, context):
    print("incoming event:" + json.dumps(event))
    print("context:" + json.dumps(event))
    """
    clientRequestToken="{}-{}".format(prefix,str(uuid.uuid4()))
    response = client.start_pipeline_execution(
    name='string',
    clientRequestToken=clientRequestToken
    )
 

    """
    return event
