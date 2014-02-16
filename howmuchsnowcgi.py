#!/usr/bin/env python2.7
import sys
from webapp2 import WSGIApplication, RequestHandler
sys.path.append('/home/mmachenry/HowMuchSnow')
import howmuchsnow
import pages

class MainHandler (RequestHandler):
    def get(self):
        ip_addr = self.request.environ['REMOTE_ADDR']
        inches = howmuchsnow.how_much_snow_ipv4(ip_addr)
        amount = format_amount(inches)
        homepage = pages.make_homepage(amount)
        return self.response.write(homepage)

class FAQHandler (RequestHandler):
    def get(self):
        return self.response.write(pages.faq)

def unit_word (inches):
    if inches == 1:
        return "inch"
    else:
        return "inches"

def format_amount(inches):
    reported_value = int(round(inches))
    unit = unit_word(reported_value)
    return str(reported_value) + ' ' + unit

app = WSGIApplication([('/', MainHandler),
                       ('/faq', FAQHandler)],
                      debug=True)

if __name__ == '__main__':
    app.run()

