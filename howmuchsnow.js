function getSnow(url){
    var req = new XMLHttpRequest();
    var result = "empty";
    req.open("GET", url, true);
    req.onreadystatechange = function () {
        if (req.readyState === 4){
            // result = req.responseText;
            result = JSON.parse(req.responseText);
            // if (result === "") {
            if (result.inches === "") {
                $("#out_of_range_msg").show();
            } else {
                // $("#snow").html(result);
                $("#snow").html(result.inches);
                $("#coordinates").html(result.coords);
            }
        }
    };
    req.send(null);
}

function useGeolocation(position){
    var lat = position.coords.latitude;
    var lon = position.coords.longitude;
    var url = "/?geo=1&lat=" + lat + "&lon=" + lon;
    getSnow(url);
}

function useIP () {
    getSnow("/?ip=1");
}

$(function (){
    if (geoPosition.init()) {
        geoPosition.getCurrentPosition(useGeolocation, useIP);
    }
    else {
        useIP();
    }
    useIP();
});
