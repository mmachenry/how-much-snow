create table location (
    id serial,
    latitude numeric(7,4) not null,
    longitude numeric(7,4) not null,
    unique (latitude, longitude)
);

create index location_latitude on location (latitude);
create index location_longitude on location (longitude);

create table prediction (
    created timestamp not null,
    predictedfor timestamp not null,
    locationid integer not null,
    apcp real not null,
    tmp real not null,
    csnow integer not null,
    metersofsnow real
);

create index prediction_location on prediction(locationid);

create or replace function distance (lat1 real, lon1 real, lat2 real, lon2 real) returns real as $$
/*
The distance in km between the two points.

Example test case:
select distance (40, -72, 35, -78);
distance 
----------
765.897
*/
    declare
        lon real;
        lat real;
        longitudes real;
        latitudes real;
        distance real;
    begin
        lon := 111.3194907784152;
        lat := 110.5743885571743;
        longitudes = lon*abs(lon1-lon2)*cos(3.14/180 * (lat1+lat2) / 2.0);
        latitudes = lat*abs(lat1-lat2);
        return sqrt(latitudes^2 + longitudes^2);
    end;
    $$
    language plpgsql
;
