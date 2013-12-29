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
    predictions = sa.Table('predictions', metadata, autoload = True)
    return conn, predictions

def get_triangulation(conn, predictions):
    '''Get a triangulation of the weather data points. Only needs
    to be done when new data is inserted.'''
    #all weather points, qhull_options('QJ'))
    points = conn.execute(sa.select([predictions.c.latitude,
                                    predictions.c.longitude]))
    triangulation = Delauney(points)
    return triangulation

def get_persistent():
    conn, predictions = get_db()
    return (conn, predictions, get_triangulation(conn, predictions))

def get_triangle_predictions(points, conn, predictions):
    '''Given the coordinates of three points, find their predicted amounts
    of snow in the database.'''
    matches = [sa.and_(predictions.c.latitude == tri_lat,
                       predictions.c.longitude == tri_lon)
               for (tri_lat, tri_lon) in points]
    selection = sa.select(predictions.c.inches).where(sa.or_(*matches))
    return conn.execute(selection)

#def insert_predictions(conn, predictions):
    #weather_data = #TODO get weather data from the internet
    #insertion = sa.insert() #TODO look up insert syntax
    #conn.execute(insertion)
    #TODO refresh triangulation

def get_nearest((lat, lon), (conn, predictions)):
    '''Given user coordinates, find the three nearest points in the database.'''
    distance = sa.func.global_dist(predictions.c.latitude,
                                   predictions.c.longitude,
                                   lat,
                                   lon).label('distance')
    selection = sa.select([distance, predictions]).orderby('distance').limit(3)
    return conn.execute(selection)

