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
DB = 'postgresql://howmuchsnow:howmuchsnow@localhost/howmuchsnow'

def main ():
    temp_dir = tempfile.mkdtemp()
    download_weather_data(temp_dir)
    convert_to_csv(temp_dir)
    connection = get_connection(DB)
    transaction = connection.begin()
    do_db_import(connection, temp_dir)
    transaction.commit()
    shutil.rmtree(temp_dir)

def download_weather_data (temp_dir):
    # Connect to the FTP site.
    ftp = FTP('ftp.hpc.ncep.noaa.gov')
    ftp.login()

    filenames = get_latest_run_filenames(ftp)

    # Download all the new files.
    for filename in filenames:
        if re.match(r'^sref_xwwd_us_[0-9]{8}09f[0-9]{2}.grb$', filename):
            local_filename = os.path.join(temp_dir, filename)
            file = open(local_filename, 'wb')
            ftp.retrbinary('RETR '+ filename, file.write)
            file.close()
    ftp.close()

def get_latest_run_filenames (ftp):
    ftp.cwd('winwx_impact')
    latestDirectory = max(filter(
        lambda dir: re.match("^[0-9]+$", dir),
        ftp.nlst()))
    ftp.cwd(latestDirectory)
    filenames = ftp.nlst()
    l = len(filenames)
    return sorted(filenames)[l-30:l-1]

def convert_to_csv (temp_dir):
    DEVNULL = open(os.devnull, 'w')
    for grb_filename in glob.glob(os.path.join(temp_dir, "*.grb")):
        csv_filename = grb_filename + ".csv"
        subprocess.call(
            [WGRIB_PROGRAM, "-csv", csv_filename, grb_filename],
            stderr = subprocess.STDOUT, stdout = DEVNULL)
        
def get_connection (db):
    return sqlalchemy.create_engine(DB).connect()

def do_db_import (dbh, temp_dir):
    create_temp_table(dbh)
    store_directory_in_database(dbh, temp_dir)
    create_locations(dbh)
    merge_prediction_data(dbh)
    remove_old_predictions(dbh)

def create_temp_table (dbh):
    dbh.execute("create temporary table predictiontemp (created timestamp, predictedfor timestamp, latitude numeric(7,4), longitude numeric(7,4), metersofsnow real)") 

def store_directory_in_database (dbh, temp_dir):
    for filename in glob.glob(os.path.join(temp_dir, "*.csv")):
        store_file_in_database(dbh, filename)

def store_file_in_database (dbh, filename):
    rows = []
    with open(filename, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            if row[2] == "TSNOW.ens-mean":
                rows.append("(" + ",".join([
                    "now()", #created
                    "'"+row[1]+"'",  #predictedfor
                    row[5],  #latitude
                    row[4],  #longitude
                    row[6]   #metersofsnow
                ]) + ")")
            elif  row[2] == "FRZR.ens-mean":
                pass
            else:
                print "Unknown row type: " + row[2]

    dbh.execute("""
        insert into predictiontemp (
            created,
            predictedfor,
            latitude,
            longitude,
            metersofsnow
        ) values
    """ + ",".join(rows))

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
            prediction (created, predictedfor, locationid, metersofsnow)
        select
            predictiontemp.created,
            predictiontemp.predictedfor,
            location.id,
            predictiontemp.metersofsnow
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
            created = predictiontemp.created,
            metersofsnow = predictiontemp.metersofsnow
        from
            predictiontemp
            join location
                on location.latitude = predictiontemp.latitude
                and location.longitude = predictiontemp.longitude
        where
            prediction.predictedfor = predictiontemp.predictedfor
            and location.id = prediction.locationid
    """)

def remove_old_predictions(dbh):
    dbh.execute("delete from prediction where predictedfor < now()")

if __name__ == "__main__":
    main()

