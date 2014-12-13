from itertools import groupby
import sqlalchemy as sa
import howmuchsnow
import sys
import pprint
import numpy as np

places = {
    "sean" : (40.659437,-75.3995089),
    "platsburg" : (44.6961485,-73.4569312)
}

user_loc = places['sean']

engine = sa.create_engine(howmuchsnow.DB)
conn = engine.connect()

hours = howmuchsnow.get_nearest_by_hour(user_loc, conn)

for hour in hours:
    time = hour[0][3]
    print time,": ",howmuchsnow.interpolate_closest(np.asarray(hour), user_loc)
    for loc in hour:
        print "    (",  loc[0], ",", loc[1], ") : ", loc[2]
    print

print howmuchsnow.how_much_snow_gps(user_loc, conn)

