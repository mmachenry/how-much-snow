import os
import glob
import re
from ftplib import FTP
import tempfile
import shutil
import csv
import subprocess
import sqlalchemy

WGRIB_PROGRAM = "/home/mmachenry/wgrib2-v0.1.9.4/bin/wgrib2"
DB = 'postgresql://howmuchsnow:howmuchsnow@localhost/howmuchsnow_test'
SOURCE_FILE_REGEXP = "sref.t(03|09|15|21)z.pgrb212.mean_3hrly.grib2"
MAX_CSV_CHUNK_SIZE = 100000

def main ():
    #print "Starting."
    temp_dir = tempfile.mkdtemp()
    #print "Downloading to " + temp_dir
    download_weather_data(temp_dir)
    #print "Converting to CSV."
    filenames = convert_to_csv(temp_dir)
    #print "Connecting to DB."
    connection = get_connection(DB)
    transaction = connection.begin()
    #print "Importing ", filenames
    do_db_import(connection, filenames)
    #print "Closing transaction."
    transaction.commit()
    #print "Removing " + temp_dir
    shutil.rmtree(temp_dir)

def download_weather_data (temp_dir):
    ftp = FTP('ftpprd.ncep.noaa.gov')
    ftp.login()
    filename = get_latest_run_filenames(ftp)
    if filename:
        download_file(ftp, temp_dir, filename)
    ftp.close()

def get_latest_run_filenames (ftp):
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
    file.close()

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

def get_connection (db):
    return sqlalchemy.create_engine(DB).connect()

def do_db_import (dbh, filenames):
    create_temp_table(dbh)
    store_files_in_database(dbh, filenames)
    create_locations(dbh)
    merge_prediction_data(dbh)
    remove_old_predictions(dbh)

def create_temp_table (dbh):
    dbh.execute("create temporary table predictiontemp (created timestamp, predictedfor timestamp, latitude numeric(7,4), longitude numeric(7,4), apcp real, tmp real, csnow integer)") 

def store_files_in_database (dbh, filenames):
    initial_insert = True
    for filename in filenames:
        #print filename, initial_insert
        m = re.search("grib2[.]([A-Z]+)[.]csv", filename)
        weather_type = m.group(1)
        store_file_in_database(dbh, initial_insert, weather_type, filename)
        initial_insert = False

def store_file_in_database (dbh, initial_insert, weather_type, filename):
    for csv_chunk in read_csv_rows(filename):
        values = ",".join(map(csv_row_to_values, csv_chunk))
        if initial_insert:
            dbh.execute(
                "insert into predictiontemp (predictedfor, latitude, longitude, "
                + weather_type + ") values " + values)
        else:
            dbh.execute(
                "update predictiontemp set " + weather_type +
                " = update_rows.val from (values " +
                values + ") as update_rows (t, lat, lon, val) where" + """
                to_timestamp(update_rows.t, 'YYYY-MM-DD HH24:MI:SS') =
                    predictiontemp.predictedfor
                and update_rows.lat = predictiontemp.latitude
                and update_rows.lon = predictiontemp.longitude """)

def read_csv_rows (filename):
    with open(filename, 'r') as f:
        reader = csv.reader(f)
        rows = []
        chunk_size = 0
        for row in reader:
            rows.append(row)
            chunk_size += 1
            if chunk_size >= MAX_CSV_CHUNK_SIZE:
                yield rows
                rows = []
                chunk_size = 0

def csv_row_to_values (row):
    return "(" + ",".join([
        "'"+row[1]+"'",  #predictedfor
        row[5],  #latitude
        row[4],  #longitude
        row[6]   #data point value
        ]) + ")"

def create_locations (dbh):
    dbh.execute("""
        insert into
            location (latitude, longitude)
        select
            latitude,
            longitude
        from
            predictiontemp
        where
            not exists (
                select
                    1
                from
                    location existing
                where
                    existing.latitude = predictiontemp.latitude
                    and existing.longitude = predictiontemp.longitude
            )
        group by
            latitude,
            longitude
    """)

def merge_prediction_data (dbh):
    dbh.execute("""
        insert into
            prediction (created, predictedfor, locationid, apcp, tmp, csnow)
        select
            now(),
            predictiontemp.predictedfor,
            location.id,
            predictiontemp.apcp,
            predictiontemp.tmp,
            predictiontemp.csnow
        from
            predictiontemp
            join location
                on location.latitude = predictiontemp.latitude
                and location.longitude = predictiontemp.longitude
        where
            not exists (
                select
                    1
                from
                    prediction existing
                where
                    predictiontemp.predictedfor = existing.predictedfor
                    and location.id = existing.locationid
            )
    """)

    dbh.execute("""
        update
            prediction
        set 
            created = now(),
            apcp = predictiontemp.apcp,
            tmp = predictiontemp.tmp,
            csnow = predictiontemp.csnow
        from
            predictiontemp
            join location
                on location.latitude = predictiontemp.latitude
                and location.longitude = predictiontemp.longitude
        where
            prediction.predictedfor = predictiontemp.predictedfor
            and location.id = prediction.locationid
    """)

    dbh.execute("""
        update
            prediction
        set
            metersofsnow =
                case when csnow = 1
                     then (281.15-tmp) * apcp * 0.001
                     else 0 end
    """)


def remove_old_predictions(dbh):
    dbh.execute("delete from prediction where predictedfor < now()")

if __name__ == "__main__":
    main()

