function useGeolocation(position){
    var lat = position.coords.latitude;
    var lon = position.coords.longitude;
    var invokeUrl = "https://oziaoyoi7f.execute-api.us-east-1.amazonaws.com/prod/prediction";
    var url = invokeUrl + "?lat=" + lat + "&lon=" + lon;
    var req = new XMLHttpRequest();
    var result = "empty";
    req.open("GET", url, true);
    req.onreadystatechange = function () {
        if (req.readyState === 4){
            result = JSON.parse(req.responseText);
            if (result.inches === "") {
                $("#out_of_range_msg").show();
            } else {
                $("#snow").html(result.inches).css("font-size", "120pt");
                $("body").css("text-align", "center");
                $("#coordinates").html(result.coords);
            }
        }
    };
    req.send(null);
}

function onDenied () {
    $("#coordinates").html("Location permission denied.");
}

// ellipsis animation
var dots = 0;

function animateDots() {
    if (dots < 3) {
        $('#dots').append('.');
        dots++;
    } else {
        $('#dots').html('');
        dots = 0;
    }
}

$(function (){
    setInterval(animateDots, 600);

    if (geoPosition.init()) {
        geoPosition.getCurrentPosition(useGeolocation, onDenied);
    }
    else {
        $("#snow").html("Sorry, we can't get your location.");
    }
});

