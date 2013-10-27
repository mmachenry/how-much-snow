from subprocess import check_output
import re
from glob import glob
import pygeoip

directory = "/Users/mmachenry/howmuchsnow"
program = directory + "/wgrib2-v0.1.9.4/bin/wgrib2"

def howMuchSnowIPv4 (ip_address):
    return howMuchSnowGPS (IPv4toGPS (ip_address))

def IPv4toGPS (ip_address):
    gi = pygeoip.GeoIP('GeoLiteCity.dat')
    record = gi.record_by_addr(ip_address)
    return record['latitude'], record['longitude']

def howMuchSnowGPS ((lat, lon)):
    '''Takes user's latitude and longitude. Returns amount of snow in inches.'''
    amts_snow = [howMuchSnowOneFile(lat, lon, f) for f in glob(directory + '/data/*grb')]
    return metersToInches(max(amts_snow))

def howMuchSnowOneFile (lat, lon, filename):
    '''Takes user's latitude and longitude and the forecast file for one three-hour window. Returns max amount of snow.'''
    command = [program, "-lon", str(lon), str(lat), filename]
    output = check_output(command)
    snow_line = re.match(r'(?m)^1.*?val=([0-9.]+)$', output) 
    amt_snow = snow_line.group(1) 
    return float(amt_snow)

def metersToInches (m):
    return m * 39.37

def test_howMuchSnowOneFile():
    howMuchSnowOneFile(40, 200, directory + '/data/sref_xwwd_us_2013102609f45.grb')

print howMuchSnowIPv4('209.6.55.158')
print howMuchSnowGPS((45.95, -107.9))

