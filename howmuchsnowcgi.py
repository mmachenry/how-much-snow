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
    else:
        ip_addr = request.environ['REMOTE_ADDR']
        inches = howmuchsnow.how_much_snow_ipv4(ip_addr, conn)
        response_body = pages.make_homepage(inches)
        yield response_body

if __name__ == '__main__':
    WSGIServer(application).run()

