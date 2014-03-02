def make_homepage (str_amount):
    return """
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<body style="text-align: center; padding-top: 200px;">
<a style="font-weight: bold; font-size: 120pt; font-family:Helvetica, sans-serif; text-decoration: none; color: black;">
""" + str_amount + """
</body>
</html>
    """

homepage = """
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>How Much Snow Am I Going To Get?</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>

<body style="text-align: center; padding-top: 200px;">

<span id="snow" style="font-weight: bold; font-size: 120pt; font-family:
Helvetica, sans-serif; text-decoration: none; color: black;">
</span>

<!--Assuming you're near <a href="https://www.google.com/maps?q=%(lat)s%2C%(lon)s">%(lat)s&deg;%(NS)s %(lon)s&deg;%(EW)s</a> |
Counts only snow falling after %(time)s -->
<div style="position: fixed;
  right: 15px;
  bottom: 15px;"><a style="font-weight: bold; color: grey; text-decoration: none;" href="/?faq=1">More Information</a></div>

<script src="http://code.jquery.com/jquery-1.11.0.min.js"></script>
<script src="http://code.jquery.com/jquery-migrate-1.2.1.min.js"></script>

<script src="geoPosition.js"></script>
<script src="howmuchsnow.js"></script>

</body>
</html>
    """

faq = """
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>How Much Snow Am I Going To Get?</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <style type="text/css">
    p.q {font-weight:bold;}
    a {text-decoration:underline;
      color: black;}
    body {text-align: left;
          padding-left: 200px;
          padding-bottom: 50px;
          padding-top: 50px;}
    </style>
</head>

<div>
<p class="q">Q. Who made this site?</p>
<p class="a">A. <a href="http://xkcd.com/">Randall Munroe</a>, <a href="http://turingcompletewasteoftime.blogspot.com/">Mike MacHenry</a>, and <a href="http://people.umass.edu/ppizzo/">Presley Pizzo</a>.</p>
</div>

<div>
<p class="q">Q. What does the number represent?</p>
<p class="a">A. The predicted accumulation in your area from the largest snowstorm you're expected to get during the next few days.</p>
</div>

<div>
<p class="q">Q. Where do these forecasts come from?</p>
<p class="a">A. The US National Weather Service's <a href="http://www.hpc.ncep.noaa.gov/wwd/impactgraphics/">Short-Range Ensemble Forecast</a> model.</p>
</div>

<div>
<p class="q">Q. What if you got my location wrong?</p>
<p class="a">A. Sorry :(</p>
</div>

<div>
<p class="q">Q. What if I want to see the forecast for a different location?</p>
<p class="a">A. Use a <a href="http://www.hpc.ncep.noaa.gov/wwd/winter_wx.shtml">real weather site</a>.</p>
</div>

<div>
<p class="q">Q. What if I live outside the US?</p>
<p class="a">A. Use a real weather site.</p>
</div>

<div>
<p class="q">Q. How can I find out when the snow is supposed to start?</p>
<p class="a">A. Use a real weather site.</p>
</div>

<div>
<p class="q">Q. What if I want to see the forecast for a specific day?</p>
<p class="a">A. Use a real weather site.</p>
</div>

<div>
<p class="q">Q. What if I want to know how much rain or ice I'm going to get?</p>
<p class="a">A. Use a real weather site.</p>

</div>

<div>
<p class="q">Q. What if I want to know how many people are in space right now?</p>
<p class="a">A. Use <a href="http://www.howmanypeopleareinspacerightnow.com">How Many People
Are In Space Right Now?</a>.</p>
</div>

</body>
</html>
"""

