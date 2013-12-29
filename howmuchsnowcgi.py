#!/usr/bin/env python2.7
import sys
#from flup.server.fcgi import WSGIServer
from webapp2 import WSGIApplication, RequestHandler
sys.path.append('/home/mmachenry/HowMuchSnow')
from howmuchsnow import how_much_snow_ipv4
from model import get_persistent

#TODO figure out how to refresh data
persistent = get_persistent()

def make_homepage(value, unit):
    return """
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>How Much Snow Am I Going To Get?</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>

<body style="text-align: center; padding-top: 200px;">

<a style="font-weight: bold; font-size: 120pt; font-family:
Helvetica, sans-serif; text-decoration: none; color: black;">
%(value)s %(unit)s
</a>

<a href="/faq.html" style="font-size: 14pt; color: grey; font-family: Helvetica;">?</a>

</body>
</html>
    """

faq = """
"""

class MainHandler (RequestHandler):
    def get(self):
        ipv4 = self.request.environ['REMOTE_ADDR']
        inches = how_much_snow_ipv4(ipv4, persistent)
        reported_value = int(round(inches))
        unit = unit_word(reported_value)
        homepage = make_homepage(str(reported_value), unit)
        return self.response.write(homepage)

class FAQHandler (RequestHandler):
    def get(self):
        return self.response.write(faq)

def unit_word (inches):
    if inches == 1:
        return "inch"
    else:
        return "inches"


app = WSGIApplication([('/', MainHandler),
                       ('/faq', FAQHandler)],
                      debug=True)


if __name__ == '__main__':
    app.run()

