import os
import glob
import re
from ftplib import FTP

WEATHER_DATA = '/home/mmachenry/public_html/HowMuchSnow/weather_data'

# Connect to the database
ftp = FTP('ftp.hpc.ncep.noaa.gov')
ftp.login()

# Delete all the files in the directory.
for filename in glob.glob(os.path.join(WEATHER_DATA, "*.grb")):
    os.remove(filename)

# Get a list of all the new files.
ftp.cwd('winwx_impact')
latestDirectory = max(filter(lambda dir: re.match("^[0-9]+$", dir), ftp.nlst()))
print latestDirectory
ftp.cwd(latestDirectory)

# Download all the new files.
for filename in ftp.nlst():
    extension = os.path.splitext(filename)[1]
    if extension == ".grb":
        local_filename = os.path.join(WEATHER_DATA, filename)
        file = open(local_filename, 'wb')
        ftp.retrbinary('RETR '+ filename, file.write)
        file.close()

ftp.close()

