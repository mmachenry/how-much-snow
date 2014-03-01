#!/usr/bin/env python2.7
import sys
from flup.server.fcgi import WSGIServer
from cgi import parse_qs
sys.path.append('/home/mmachenry/HowMuchSnow')
import howmuchsnow
import pages

def application(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/html')])
    parameters = parse_qs(environ.get('QUERY_STRING', ''))
    if 'faq' in parameters:
        yield pages.faq
    else:
        response_body = pages.make_homepage(
            howmuchsnow.how_much_snow_ipv4(environ['REMOTE_ADDR']))
        yield response_body

if __name__ == '__main__':
    WSGIServer(application).run()

