import sys
sys.path.append("/home/mmachenry/src/how-much-snow")
from itertools import groupby
import sqlalchemy as sa
import howmuchsnow
import config
import pprint
import numpy as np

places = {
    "sean" : (40.659437,-75.3995089),
    "platsburg" : (44.6961485,-73.4569312),
    "bozeman" : (45.683884, -111.039916),
    "phillips" : (45.660854, -90.217734),
    "mike" : (42.401981,-71.122687)
}

user_loc = places['mike']

engine = sa.create_engine(config.DB)
conn = engine.connect()

print howmuchsnow.how_much_snow_gps(user_loc, conn)

