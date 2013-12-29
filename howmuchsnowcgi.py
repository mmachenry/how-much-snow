#!/usr/bin/env python2.7
import sys
from flup.server.fcgi import WSGIServer
sys.path.append('/home/mmachenry/HowMuchSnow')
from howmuchsnow import how_much_snow_ipv4
from model import get_persistent


def application(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/html')])
    response_body = make_html_page(how_much_snow_ipv4(environ['REMOTE_ADDR'], persistent))
    yield response_body

def make_html_page (inches):
    reported_value = int(round(inches))
    return """
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>How Much Snow Am I Going To Get?</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>

<body style="text-align: center; padding-top: 200px;">

<a title = "Maximum predicted accumulation of snow on the ground
over the next 87 hours (about 3 and a half days)."
style="font-weight: bold; font-size: 120pt; font-family:
Arial, sans-serif; text-decoration: none; color: black;">
""" + str(reported_value) + " " + unit_word(reported_value) + """
</a>

</body>
</html>
    """

def unit_word (inches):
    if inches == 1:
        return "inch"
    else:
        return "inches"

persistent = get_persistent()
WSGIServer(application).run()

