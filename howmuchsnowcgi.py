#!/usr/bin/env python2.7
import sys
from flup.server.fcgi import WSGIServer
from cgi import parse_qs
sys.path.append('/home/mmachenry/HowMuchSnow')
import howmuchsnow
import pages
import sqlalchemy as sa

engine = sa.create_engine(howmuchsnow.DB)
conn = engine.connect()

def application(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/html')])
    parameters = parse_qs(environ.get('QUERY_STRING', ''))
    if 'faq' in parameters:
        yield pages.faq
    elif 'test' in parameters:
        # test geolocation AJAX, leads to geo or ip
        # will replace else branch once it's working
        yield pages.homepage
    elif 'geo' in parameters:
        # test JS geoposition
        lat = parameters['lat']
        lon = parameters['lon']
        inches = howmuchsnow.how_much_snow_gps((lat, lon), conn)
        #TODO yield or return?
        yield inches
    elif 'ip' in parameters:
        # test use of IP address when user doesn't share location
        ip_addr = environ['REMOTE_ADDR']
        inches = howmuchsnow.how_much_snow_ipv4(ip_addr, conn)
        yield inches
    else:
        # go to homepage, use IP address
        ip_addr = environ['REMOTE_ADDR']
        inches = howmuchsnow.how_much_snow_ipv4(ip_addr, conn)
        response_body = pages.make_homepage(inches)
        yield response_body


if __name__ == '__main__':
    WSGIServer(application).run()

