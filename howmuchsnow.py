from subprocess import check_output
import re
from glob import glob
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

def how_much_snow_one_file (lat, lon, filename):
    '''Takes user's latitude and longitude and the forecast file for one three-hour window. Returns max amount of snow.'''
    command = [WGRIB_PROGRAM, "-lon", str(lon), str(lat), filename]
    output = check_output(command)
    snow_line = re.match(r'(?m)^1.*?val=([0-9.]+)$', output) 
    if snow_line:
        amt_snow = snow_line.group(1) 
        return float(amt_snow)
    else:
        return 0
        

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
