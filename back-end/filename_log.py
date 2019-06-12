import boto3

TABLE_KEY = {'key': 'filename'}

def get_log_table ():
    dynamodb = boto3.resource('dynamodb')
    return dynamodb.Table('howmuchsnowupdatelog')

def get_most_recent_filename ():
    table = get_log_table()
    response = table.get_item(Key=TABLE_KEY)
    if 'Item' in response:
        return response['Item']['value']
    else:
        return None

def update_most_recent_filename(filename):
    table = get_log_table()
    table.update_item(
        Key = TABLE_KEY,
        UpdateExpression = 'SET #value = :value',
        ExpressionAttributeValues = {
            ':value': filename
        },
        ExpressionAttributeNames = {
            "#value": "value"
        }
    )

