#!/usr/bin/env python2.7
import sys
#from flup.server.fcgi import WSGIServer
from webapp2 import WSGIApplication, RequestHandler
sys.path.append('/home/mmachenry/HowMuchSnow')
from howmuchsnow import how_much_snow_ipv4, how_much_snow_gps
from model import get_persistent
from pages import make_homepage, faq

#TODO figure out how to refresh data
persistent = get_persistent()

def format_amount(inches):
    reported_value = int(round(inches))
    unit = unit_word(reported_value)
    return str(reported_value) + ' ' + unit

class MainHandler (RequestHandler):
    def get(self):
        #ipv4 = self.request.environ['REMOTE_ADDR']
        #inches = how_much_snow_ipv4(ipv4, persistent)
        #amount = format_amount(inches)
        homepage = make_homepage('')
        return self.response.write(homepage)

class GeoHandler (RequestHandler):
    def get(self):
        lat = self.request.get('lat')
        lon = self.request.get('lon')
        inches = how_much_snow_gps((lat, lon), persistent)
        return format_amount(inches)

class IPHandler (RequestHandler):
    def get(self):
        ipv4 = self.request.environ['REMOTE_ADDR']
        inches = how_much_snow_ipv4(ipv4, persistent)
        return format_amount(inches)

class FAQHandler (RequestHandler):
    def get(self):
        return self.response.write(faq)

def unit_word (inches):
    if inches == 1:
        return "inch"
    else:
        return "inches"


app = WSGIApplication([('/', MainHandler),
                       ('/faq', FAQHandler),
                       ('/geo', GeoHandler),
                       ('/ip', IPHandler)],
                      debug=True)


if __name__ == '__main__':
    app.run()

