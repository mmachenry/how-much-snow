import os
import glob
import re
from ftplib import FTP
import tempfile
import shutil

WEATHER_DATA = '/home/mmachenry/public_html/HowMuchSnow/weather_data'
temp_dir = tempfile.mkdtemp()

# Connect to the database
ftp = FTP('ftp.hpc.ncep.noaa.gov')
ftp.login()

# Get a list of all the new files.
ftp.cwd('winwx_impact')
latestDirectory = max(filter(lambda dir: re.match("^[0-9]+$", dir), ftp.nlst()))
print latestDirectory
ftp.cwd(latestDirectory)

# Download all the new files.
for filename in ftp.nlst():
    extension = os.path.splitext(filename)[1]
    if extension == ".grb":
        local_filename = os.path.join(temp_dir, filename)
        file = open(local_filename, 'wb')
        ftp.retrbinary('RETR '+ filename, file.write)
        file.close()

ftp.close()

# Delete all files that were in the directory before the download
old_filenames = glob.glob(os.path.join(WEATHER_DATA, "*.grb"))
for filename in old_filenames:
    os.remove(filename)

new_filenames = glob.glob(os.path.join(temp_dir, "*.grb"))
for filename in new_filenames:
    shutil.move(filename, WEATHER_DATA)

shutil.rmtree(temp_dir)
