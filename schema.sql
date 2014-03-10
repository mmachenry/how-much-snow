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
    metersofsnow real not null
);

create index prediction_location on prediction(locationid);

create or replace function distance (lat1 real, long1 real, lat2 real, long2 real) returns real as $$
    declare
        x1 real;
        x2 real;
        distance real;
    begin
        /* Longitude is already in correct format (degrees east of PM)
         Latitude should be subtracted from 90, southern lats are negative
         so this gives degrees south of the North Pole for all latitudes */
        x1 := 90 - lat1;
        x2 := 90 - lat2;
        distance := sqrt((x1 - x2)^2 + (long1 - long2)^2);
        return distance;
    end;
    $$
    language plpgsql
;
