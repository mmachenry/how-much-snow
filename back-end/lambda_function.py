import sqlalchemy as sa
import simplejson as json
import datetime
import config

engine = sa.create_engine(config.DB)
conn = engine.connect()

def lambda_handler(event, context):
    lat = event['queryStringParameters']['lat']
    lon = event['queryStringParameters']['lon']

    user_object = {
        'meters': get_from_db((lat, lon), conn),
        'data' : get_nearby_predictions((lat, lon), conn)
    }

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
        ''')
    result = conn.execute(query, lat = latitude, lon = longitude)
    return [dict(row) for row in result]

def json_converter(o):
    if isinstance(o, datetime.datetime):
        return o.__str__()

def get_from_db (loc, conn):
    '''Given user coordinates and a database connection, get the weighted
       average by distance squared of all of the nearby stations. Returns
       amount of snow in inches.
    '''
    (latitude, longitude) = loc
    query = sa.text('''
        select
            sum(influence * msnow) / sum (influence)
        from (
            select
                1 / distance(latitude, longitude, :lat, :lon)^2 influence,
                sum ( metersofsnow * least(extract(epoch from prediction.predictedfor - now()) / (60*60*3), 1) ) msnow
            from
                prediction
            join
                location on location.id = prediction.locationid
            where
                distance(latitude, longitude, :lat, :lon) < 50
            group by
                latitude,
                longitude
            ) aggregate
    ''')
    (result,) = conn.execute(query, lat = latitude, lon = longitude).first()
    return result
