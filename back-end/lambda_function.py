import sqlalchemy as sa
import json
import config

engine = sa.create_engine(config.DB)
conn = engine.connect()

def lambda_handler(event, context):
    lat = event['queryStringParameters']['lat']
    lon = event['queryStringParameters']['lon']

    user_object = {
        'meters': get_from_db((lat, lon), conn),
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
        'body': json.dumps(user_object)
    }


def get_from_db ((latitude, longitude), conn):
    '''Given user coordinates and a database connection, get the weighted
       average by distance squared of all of the nearby stations. Returns
       amount of snow in inches.
    '''
    query = sa.text('''
        select
            sum(influence * msnow * timeremainingratio) / sum (influence)
        from (
            select
                1 / distance(latitude, longitude, :lat, :lon)^2 influence,
                least(extract(epoch from prediction.predictedfor - now()) / (60*60*3), 1) timeremainingratio,
                sum ( metersofsnow ) msnow
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
