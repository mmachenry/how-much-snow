create table prediction (
    created timestamp not null,
    predictedfor timestamp not null,
    latitude real not null,
    longitude real not null,
    metersofsnow real not null
);

create index latlon on prediction (latitude, longitude);

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
