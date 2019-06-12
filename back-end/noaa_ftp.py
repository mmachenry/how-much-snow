import os
import re
from ftplib import FTP

SOURCE_FILE_REGEXP = "sref.t(03|09|15|21)z.pgrb212.mean_3hrly.grib2"

def connect_to_ftp ():
    ftp = FTP('ftpprd.ncep.noaa.gov')
    ftp.login()
    return ftp

def get_latest_run_filename (ftp):
    ftp.cwd('pub/data/nccf/com/sref/prod')
    for date_dir in sorted(ftp.nlst(), reverse=True):
        three_hourly_dirs = ftp.nlst(date_dir)
        for three_hourly_dir in sorted(three_hourly_dirs, reverse=True):
            filenames = ftp.nlst(three_hourly_dir + "/ensprod")
            for filename in filenames:
                if re.search(SOURCE_FILE_REGEXP, filename):
                    return filename
    return None

def download_file(ftp, temp_dir, filename):
    local_filename = os.path.join(temp_dir, os.path.basename(filename))
    file = open(local_filename, 'wb')
    ftp.retrbinary('RETR '+ filename, file.write)

