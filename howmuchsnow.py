from itertools import groupby
import pygeoip
import sqlalchemy as sa
import numpy as np

WEATHER_DIRECTORY = "/home/mmachenry/public_html/HowMuchSnow/weather_data"
WGRIB_PROGRAM = "/home/mmachenry/wgrib2-v0.1.9.4/bin/wgrib2"
GEOIP_DATABASE = "/usr/share/GeoIP/GeoLiteCity.dat"
DB = 'postgresql://howmuchsnow:howmuchsnow@localhost/howmuchsnow'
DELTA_LAT = 0.4 
DELTA_LON = 0.4

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
    coordinates = [(
        point['latitude'],
        point['longitude'],
        point['metersofsnow'],
        point['predictedfor'])
        for point in nearest]
    keyfunc = lambda point: point[3]
    hours = [list(val) for (key, val) in groupby(coordinates, keyfunc)]
    try:
        amounts = [interpolate_closest(np.asarray(hour), user_loc)
            for hour in hours]
        maxm = max(amounts)
        if maxm < 0: # this can happen if you're outside your triangle
            maxm = 0
        if np.isnan(maxm): # if three points are in a line
            raise ValueError
        inches = meters2inches(maxm)
        return format_amount(inches)
    except (AssertionError, ValueError) as e:
        return ""

def distance ((lat1, lon1), (lat2, lon2)):
    return ((lat1 - lat2) ** 2 + (lon1 - lon2) ** 2) ** (0.5)
 
def interpolate_closest (points, (lat, lon)):
    '''A weighted average of the amount of snow for a given location based on
    the amount of snow at other locations. Inverse distance weighted'''
    total = 0;
    influence = [];
    for (plat, plon, snow, time) in points:
        i = 1 / distance((plat, plon), (lat, lon))
        influence.append(i)
        total += i * snow
    return total / sum(influence)

def get_nearest((lat, lon), conn):
    '''Given user coordinates and a database connection, get all rows for the
    three nearest points in the database.'''
    query = sa.text('''
select
    prediction.predictedfor,
    cast (closestThree.latitude as real) as latitude,
    cast (closestThree.longitude as real) as longitude,
    prediction.metersofsnow
from
    prediction
    join (
        select
            id,
            latitude,
            longitude
        from
            location
        where
            latitude between :x - :delta_lat and :x + :delta_lat
            and longitude between :y - :delta_lat and :y + :delta_lon
        order by
            distance(latitude,longitude, :x, :y)
        limit
            3
    ) closestThree
    on prediction.locationid = closestThree.id
order by
    prediction.predictedfor
    ''')
    return conn.execute(
        query,
        x = lat,
        y = lon,
        delta_lat = DELTA_LAT,
        delta_lon = DELTA_LON)

def meters2inches (m):
    return m * 39.37

def format_amount(inches):
    reported_value = int(round(inches))
    unit = unit_word(reported_value)
    return str(reported_value) + ' ' + unit

def unit_word (inches):
    if inches == 1:
        return "inch"
    else:
        return "inches"

def make_coordinates(lat, lon):
    return '''Assuming you're near <a
        href="https://www.google.com/maps?q={0}%2C{1}">{0}&deg;N
        {1}&deg;W</a> | '''.format(lat, lon)
