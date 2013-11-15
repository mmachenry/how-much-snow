import time
import os
import glob
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
ftp.cwd(time.strftime("%Y%m%d"))
filenames = []
ftp.retrlines('NLST', filenames.append)

# Download all the new files.
for filename in filenames:
    extension = os.path.splitext(filename)[1]
    if extension == ".grb":
        local_filename = os.path.join(WEATHER_DATA, filename)
        file = open(local_filename, 'wb')
        ftp.retrbinary('RETR '+ filename, file.write)
        file.close()

ftp.close()

