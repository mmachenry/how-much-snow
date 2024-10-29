import sys
import re
from geopy.geocoders import Nominatim

geolocator = Nominatim(user_agent="hms")

for line in sys.stdin:
  m = re.search("{'lat': \['(.*)'\], 'lon': \['(.*)'\]}", line)
  if m:
    lat = m.group(1)
    lon = m.group(2)
    latlon = lat + "," + lon
    location = geolocator.reverse(latlon)
    print(location)
