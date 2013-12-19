create function globe_distance (lat1 real, long1 real, lat2 real, long2 real) returns real {
    as $$
    declare
        /* radius of the earth in km. Unit shouldn't matter because distances
         will just be compared to each other. */
        radius constant integer := 6373;
        phi1 real;
        phi2 real;
        angle real;
        distance real;
    begin
        /* Longitude is already in correct format (degrees east of PM)
         Latitude should be subtracted from 90, southern lats are negative
         so this gives degrees south of the North Pole for all latitudes */
        phi1 := 90 - lat1;
        phi2 := 90 - lat2;
        angle := acos(sin(phi1) * sin(phi2) * cos(long1 - long2) + cos(phi1) * cos(phi2));
        distance := radius * angle;
        return distance;
    end;
    $$
    language SQL
    immutable
    returns null on null input;
}





