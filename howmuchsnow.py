import pygeoip
import numpy as np
from itertools import groupby
from scipy.interpolate import griddata
from model import get_triangle_predictions, get_nearest


GEOIP_DATABASE = "/usr/share/GeoIP/GeoLiteCity.dat"

def how_much_snow_ipv4 (ip_address):
    return how_much_snow_gps (ipv4_to_gps (ip_address))

def ipv4_to_gps (ip_address):
    '''Takes IP address and returns latitude and longitude of the nearest city.'''
    gi = pygeoip.GeoIP(GEOIP_DATABASE)
    record = gi.record_by_addr(ip_address)
    return record['latitude'], record['longitude']

def how_much_snow_gps (user_loc, persistent):
    '''Takes a tuple of a user's estimated latitude and longitude, and a
    database connection. Returns a list of the three shortest distances from
    there to places in the database, and a list of the amounts of snow
    predicted for those three places.'''
    # get nearest 3 points group by predictedfor
    # for each group, send to interpolate_closest
    # return max of result
    nearest = get_nearest(user_loc, persistent)
    coordinates = [(point['latitude'], point['longitude'], point['inches'], point['predictedfor'])
                   for point in nearest]
    keyfunc = lambda point: point[3]
    hours = [list(val) for (key, val) in groupby(coordinates, keyfunc)]
    amounts = [interpolate_closest(hour, user_loc) for hour in hours]
    return max(amounts)

def interpolate_closest (coordinates, lat, lon):
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
    d = np.dot(coordinates[0], normal)
    # z = (ax + by - d) / -c
    return np.dot([a, b, -d], [lat, lon, 1]) / -c

def get_triangle(user_lat, user_lon, triangulation):
    #TODO can I do this by point id somehow?
    triangle_index = triangulation.find_simplex([user_lat, user_lon])
    triangle = triangulation.simplices[triangle_index]
    return triangulation.points[triangle]

def interpolate_triangle ((user_lat, user_lon), (conn, prediction, triangulation)):
    '''Takes a tuple of the user's estimated latitude and longitude, and a database connection.
    Finds a triangle of points surrounding the user's coordinates that are in the weather database.
    Interpolates from the triangle to the user's coordinates. Returns predicted amount of snow.'''
    tri_xy = get_triangle(user_lat, user_lon, triangulation)
    tri_z = get_triangle_predictions(tri_xy, conn, prediction)
    coordinates = [(point['inches'], point['predictedfor'])
                   for point in tri_z]
    keyfunc = lambda point: point[1]
    hours = [list(val) for (key, val) in groupby(coordinates, keyfunc)]
    hours_zs = [[z[0] for z in hour] for hour in hours]
    amounts = [griddata(tri_xy, hour_z, [[user_lat, user_lon]]) for hour_z in hours_zs]
    return max(amounts)
