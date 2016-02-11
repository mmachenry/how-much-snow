homepage = """
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>How Much Snow Am I Going To Get?</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>

<body style="text-align: left; padding-top: 200px; padding-left: 100px; padding-right: 100px">

    <span id="snow" style="font-weight: bold; font-size: 80pt; font-family:
    Helvetica, sans-serif; text-decoration: none; color: black;">
    Getting your location<span id="dots"></span>
    </span>

    <span id="out_of_range_msg" style="display:none">You're out of range.</span>

    <div style="position: fixed;
      right: 15px;
      bottom: 15px;">
      <span style="color: grey; text-decoration: none;" id="coordinates">
      </span>
      <a style="font-weight: bold; color: grey; text-decoration: none;" href="/?faq=1">More Information</a>
    </div>

    <script src="//code.jquery.com/jquery-1.11.0.min.js"></script>
    <script src="//code.jquery.com/jquery-migrate-1.2.1.min.js"></script>

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
<p class="a">A.</p>
<p class="a"><a href="http://xkcd.com/">Randall Munroe</a> - Vowels</p>
<p class="a"><a href="https://github.com/presleyp/">Presley Pizzo</a> - Consonants</p>
<p class="a"><a href="http://turingcompletewasteoftime.blogspot.com/">Mike MacHenry</a> -
Punctuation</p>

</div>

<div>
<p class="q">Q. What does the number represent?</p>
<p class="a">A. The predicted accumulation in your area from the largest
snowstorm you're expected to get during the next few days. It only counts
snow that you haven't gotten yet, and we get updated data every six hours.</p>
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

<div style="position: fixed;
  right: 15px;
  bottom: 15px;">
  <span style="color: grey; text-decoration: none;" id="coordinates">
  </span>
  <a style="font-weight: bold; color: grey; text-decoration: none;"
  href="/">How Much Snow Am I Going to Get?</a>
</div>



</body>
</html>
"""

