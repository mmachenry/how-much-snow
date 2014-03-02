import sqlalchemy as sa
import howmuchsnow

engine = sa.create_engine(howmuchsnow.DB)
conn = engine.connect()
print howmuchsnow.how_much_snow_ipv4('174.63.41.187', conn)
