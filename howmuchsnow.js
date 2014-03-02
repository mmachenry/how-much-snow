function getSnow(url){
    var req = new XMLHttpRequest();
    req.open("GET", url, true);
    req.onreadystatechange = function(){
        if (req.readyState == 4){
            return req.responseText;
        }
    }
    req.send(null);
}

function useGeolocation(position){
    var lat = position.coords.latitude;
    var lon = position.coords.longitude;
    var url = "/?geo=1&lat=" + lat + "&lon=" + lon
    return getSnow(url);
}

function useIP(){
    return getSnow("/?ip=1");
}

$(function (){
    if geoposition.init(){
        var amount = geoPosition.getCurrentPosition(useGeolocation, useIP);
        $(#snow).html(amount);
    }
    else {
        $(#snow).html(useIP());
    }
});
