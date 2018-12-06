import sqlalchemy as sa
import simplejson as json
import datetime
import config

engine = sa.create_engine(config.DB)
conn = engine.connect()

def lambda_handler(event, context):
    lat = event['queryStringParameters']['lat']
    lon = event['queryStringParameters']['lon']
    user_object = {'data' : get_nearby_predictions((lat, lon), conn)}

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
             # Required for CORS support to work
            "Access-Control-Allow-Origin" : "*",
             # Required for cookies, authorization headers with HTTPS
            "Access-Control-Allow-Credentials" : True
        },
        'body': json.dumps(user_object, default = json_converter)
    }

def get_nearby_predictions (loc, conn):
    (latitude, longitude) = loc
    query = sa.text('''
        select
            latitude,
            longitude,
            distance(latitude, longitude, :lat, :lon) distance,
            metersofsnow,
            predictedfor
        from
            prediction
        join
            location on location.id = prediction.locationid
        where
            distance(latitude, longitude, :lat, :lon) < 50
        order by
            predictedfor,
            latitude,
            longitude
        ''')
    result = conn.execute(query, lat = latitude, lon = longitude)
    return [dict(row) for row in result]

def json_converter(o):
    if isinstance(o, datetime.datetime):
        return o.__str__()

