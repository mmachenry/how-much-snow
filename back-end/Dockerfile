FROM python:2
RUN apt-get update
RUN apt-get -y install gfortran
RUN wget http://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz
RUN tar -zxf wgrib2.tgz
RUN cd grib2 && CC=gcc FC=gfortran make
RUN pip install sqlalchemy psycopg2-binary
COPY update_weather_data.py config.py /
CMD /usr/local/bin/python /update_weather_data.py
