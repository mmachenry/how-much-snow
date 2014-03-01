from itertools import groupby
import pygeoip
import sqlalchemy as sa
import numpy as np

WEATHER_DIRECTORY = "/home/mmachenry/public_html/HowMuchSnow/weather_data"
WGRIB_PROGRAM = "/home/mmachenry/wgrib2-v0.1.9.4/bin/wgrib2"
GEOIP_DATABASE = "/usr/share/GeoIP/GeoLiteCity.dat"
DB = 'postgresql://howmuchsnow:howmuchsnow@localhost/howmuchsnow'

def how_much_snow_ipv4 (ip_address, conn):
    return how_much_snow_gps (ipv4_to_gps (ip_address), conn)

def ipv4_to_gps (ip_address):
    gi = pygeoip.GeoIP(GEOIP_DATABASE)
    record = gi.record_by_addr(ip_address)
    return record['latitude'], record['longitude']

def how_much_snow_gps (user_loc, conn):
    '''Takes a tuple of a user's estimated latitude and longitude, and a
    database connection. From the database, gets all rows for the nearest
    three points to the user. Groups the data by the hour the snowfall is
    predicted for. Interpolates at each hour to get a predicted amount of
    snow. Returns the max predicted amount of snow.'''
    nearest = get_nearest(user_loc, conn)
    coordinates = [(point['latitude'], point['longitude'], point['metersofsnow'], point['predictedfor'])
                   for point in nearest]
    keyfunc = lambda point: point[3]
    hours = [list(val) for (key, val) in groupby(coordinates, keyfunc)]
    amounts = [interpolate_closest(np.asarray(hour), user_loc) for hour in hours]
    return meters2inches(max(amounts))

def interpolate_closest (coordinates, (lat, lon)):
    '''Takes a list of 3 points in 3D space and the x and y coordinates of
    another point. Defines a plane over the points. Returns the z coordinate of
    the last point. The 3 coordinates do not have to surround the other point.'''
    try:
        assert len(coordinates) == 3
    except AssertionError:
        return 0
    vector1, vector2 = coordinates[0][:3] - coordinates[1][:3], coordinates[2][:3] - coordinates[1][:3]
    normal = np.cross(vector1, vector2)
    # plane equation is ax + by + cz = d
    a, b, c = normal
    d = np.dot(coordinates[0][:3], normal)
    # z = (ax + by - d) / -c
    return np.dot([a, b, -d], [lat, lon, 1]) / -c

def get_nearest((lat, lon), conn):
    '''Given user coordinates and a database connection, get all rows for the
    three nearest points in the database.'''
    query = sa.text('''select
    prediction.predictedfor,
    prediction.latitude,
    prediction.longitude,
    prediction.metersofsnow
from
    prediction,
    (
        select
            latitude,
            longitude
        from
            prediction
        group by
            latitude,
            longitude
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

def meters2inches (m):
    return m * 39.37

