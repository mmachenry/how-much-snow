import sqlalchemy as sa
from scipy.spatial import Delauney

#TODO make environment variable
db = 'psql://howmuchsnow:password@aram.xkcd.com/howmuchsnow'

def get_db():
    '''Connect to database and load table of weather data.'''
    #TODO password
    engine = sa.create_engine(db)
    conn = engine.connect()
    metadata = sa.MetaData(bind = engine)
    prediction = sa.Table('prediction', metadata, autoload = True)
    return conn, prediction

def get_triangulation(conn, prediction):
    '''Get a triangulation of the weather data points. Only needs
    to be done when new data is inserted.'''
    #all weather points, qhull_options('QJ'))
    points = conn.execute(sa.select([prediction.c.latitude,
                                    prediction.c.longitude]))
    triangulation = Delauney(points)
    return triangulation

def get_persistent():
    conn, prediction = get_db()
    return (conn, prediction, get_triangulation(conn, prediction))

#def insert_prediction(conn, prediction):
    #weather_data = #TODO get weather data from the internet
    #insertion = sa.insert() #TODO look up insert syntax
    #conn.execute(insertion)
    #TODO refresh triangulation

def get_triangle_prediction(points, conn, prediction):
    '''Given the coordinates of three points, find their predicted amounts
    of snow in the database.'''
    matches = [sa.and_(prediction.c.latitude == tri_lat,
                       prediction.c.longitude == tri_lon)
               for (tri_lat, tri_lon) in points]
    selection = sa.select([prediction.c.inches,
                           prediction.c.predictedfor]).\
                where(sa.or_(*matches)).\
                orderby(prediction.c.predictedfor)
    return conn.execute(selection)

def get_nearest((lat, lon), (conn, prediction)):
    '''Given user coordinates, get all rows for the three nearest points in the database.'''
        query = sa.text('''select
    prediction.predictedfor,
    prediction.latitude,
    prediction.longitude,
    prediction.metersofsnow
from
    predictions,
    (
        select distinct
            latitude,
            longitude
        from
            predictions
        order by
            distance(latitude,longitude, :x, :y)
        limit
            3
    ) closestThree
where
    prediction.latitude = closestThree.latitude
    and prediction.longitude = closestThree.longitude
order by
    prediction.predictedfor''')
    return conn.execute(query, x = lat, y = lon)



    #distance = sa.func.global_dist(prediction.c.latitude,
                                   #prediction.c.longitude,
                                   #lat,
                                   #lon).label('distance')

    #nearest_three = conn.execute(sa.select([distance,
                                            #prediction.c.latitude,
                                            #prediction.c.longitude]).\
                    #orderby('distance').distinct().limit(3))
    #nearest = [row['pointid'] for row in nearest_three]
    #selection = sa.select([prediction.c.latitude,
                           #prediction.c.longitude,
                           #prediction.c.metersofsnow,
                           #prediction.c.predictedfor]).\
                #where(prediction.c.pointid in nearest).\
                #groupby(prediction.c.predictedfor)
    #return conn.execute(selection)

