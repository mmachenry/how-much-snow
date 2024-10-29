import os
import boto3
import glob
import re
import tempfile
import shutil
import csv
import subprocess
import config
import filename_log
import noaa_ftp

WGRIB_PROGRAM = "/grib2/wgrib2/wgrib2"
MAX_CSV_CHUNK_SIZE = 100000

def lambda_handler(event, context):
    print("Starting.")
    temp_dir = tempfile.mkdtemp()

    print("Downloading to " + temp_dir)
    ftp = noaa_ftp.connect_to_ftp()
    filename = noaa_ftp.get_latest_run_filename(ftp)

    latest_filename = filename_log.get_most_recent_filename()
    if filename == latest_filename:
        print("Already imported: ", filename)
        ftp.quit()
        return

    noaa_ftp.download_file(ftp, temp_dir, filename)
    ftp.quit()

    print("Converting to CSV.")
    csv_filenames = convert_to_csv(temp_dir)

    print("Storing to S3 ", csv_filenames)
    store_to_s3(csv_filenames)

    print("Updating file log.")
    filename_log.update_most_recent_filename(filename)

    print("Done.")

def convert_to_csv (temp_dir):
    data_points = [
        ("APCP","APCP:surface:(0-3|3-6|6-9|9-12|12-15|15-18|18-21|21-24|24-27|27-30|30-33|33-36|36-39|39-42|42-45|45-48|48-51|51-54|54-57|57-60|60-63|63-66|66-69|69-72|72-75|75-78|78-81|81-84|84-87) hour acc"),
        ("TMP", "TMP:2 m above ground"),
        ("CSNOW","CSNOW"),
        ]
    DEVNULL = open(os.devnull, 'w')
    processed_files = []
    for grb_filename in glob.glob(os.path.join(temp_dir, "*.grib2")):
        for (file_id, weather_type) in data_points:
            csv_filename = grb_filename + "." + file_id + ".csv"
            subprocess.call(
                [WGRIB_PROGRAM,
                    "-csv", csv_filename,
                    "-match", weather_type,
                    grb_filename],
                stderr = subprocess.STDOUT, stdout = DEVNULL)
            processed_files.append(csv_filename)
    return processed_files

def store_to_s3 (csv_filenames):
    pass
