from subprocess import check_output
import re
from glob import glob
import pygeoip

WEATHER_DIRECTORY = "/home/mmachenry/public_html/HowMuchSnow/weather_data"
WGRIB_PROGRAM = "/home/mmachenry/wgrib2-v0.1.9.4/bin/wgrib2"
GEOIP_DATABASE = "/usr/share/GeoIP/GeoLiteCity.dat"

def how_much_snow_ipv4 (ip_address):
    return how_much_snow_gps (ipv4_to_gps (ip_address))

def ipv4_to_gps (ip_address):
    gi = pygeoip.GeoIP(GEOIP_DATABASE)
    record = gi.record_by_addr(ip_address)
    return record['latitude'], record['longitude']

def how_much_snow_gps ((lat, lon)):
    '''Takes user's latitude and longitude. Returns amount of snow in inches.'''
    amts_snow = [how_much_snow_one_file(lat, lon, f) for f in glob(WEATHER_DIRECTORY + '/*grb')]
    return meters2inches(max(amts_snow))

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
        

def meters2inches (m):
    return m * 39.37

