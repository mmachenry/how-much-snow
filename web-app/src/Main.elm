module Main exposing (main)

import Html exposing (Html, p, text, div, a, span)
import Html.Attributes exposing (style, href)
import Task
import Geolocation
import Json.Decode as Json
import Json.Encode
import Http

apiInvokeUrl = "https://oziaoyoi7f.execute-api.us-east-1.amazonaws.com/prod/prediction"

main =
  Html.program {
    init = init,
    update = update,
    subscriptions = (\_->Sub.none),
    view = view
  }

type alias Model = {
  location : Maybe Geolocation.Location,
  prediction : Maybe SnowResult,
  errorMessage : Maybe String
  }

type SnowResult = SnowResult String String

type Msg =
    UpdateLocation (Result Geolocation.Error Geolocation.Location)
  | UpdateSnow (Result Http.Error SnowResult)

spoofMessage : msg -> Cmd msg
spoofMessage msg =
  Task.succeed msg
  |> Task.perform identity

testLocation = {
  latitude = 42.401981,
  longitude = -71.122687,
  accuracy = 0,
  altitude = Nothing,
  movement = Nothing,
  timestamp = 0
  }

initState = { location = Nothing, prediction = Nothing, errorMessage = Nothing}

init : (Model, Cmd Msg)
--init = (initState, Task.attempt UpdateLocation Geolocation.now)
init = (initState, spoofMessage (UpdateLocation (Ok testLocation)))

-- TODO don't lose location when snow error happens
update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  UpdateLocation (Ok loc) -> ({model | location = Just loc}, getSnow loc)
  UpdateLocation (Err err) ->
    ({model | errorMessage = Just (toString err)}, Cmd.none)
  UpdateSnow (Ok x) -> ({model | prediction = Just x}, Cmd.none)
  UpdateSnow (Err err) ->
    ({model | errorMessage = Just (toString err)}, Cmd.none)

getSnow : Geolocation.Location -> Cmd Msg
getSnow loc =
  let url = apiInvokeUrl
              ++ "?lat=" ++ toString (loc.latitude)
              ++ "&lon=" ++ toString (loc.longitude)
  in Http.send UpdateSnow (Http.get apiInvokeUrl decodeSnow)

decodeSnow : Json.Decoder SnowResult
decodeSnow =
  Json.map2 SnowResult
    (Json.field "coords" Json.string)
    (Json.field "inches" Json.string)

view : Model -> Html Msg
view model =
  div [style [("text-align", "left"),
              ("padding-top", "200px"),
              ("padding-left", "100px"),
              ("padding-right", "100px")]]
      [(case model.errorMessage of
          Just str -> p [] [text str]
          Nothing -> span [style [("font-weight", "bold"),
                                  ("font-size", "80pt"),
                                  ("font-family", "Helvetica, sans-serif"),
                                  ("text-decoration", "none"),
                                  ("color", "black")]]
                          (case model.location of
                             Nothing -> [text "Getting your location..."]
                             Just _ ->
                               case model.prediction of
                                 Nothing -> [text "Getting prediction..."]
                                 Just p -> [text (toString p)])),
        footer model]

footer model =
  div [style [("position", "fixed"),
              ("right", "15px"),
              ("bottom", "15px")]]
      [ footerLocation model,
        text " | ",
        a [style [("font-weight", "bold"),
                  ("color", "grey"),
                  ("text-decoration", "none")],
           href "/?faq=1"]
          [text "More Information"]]

footerLocation model =
  span [style [("color", "grey"), ("text-decoration", "none")]]
       (case model.location of
         Nothing -> [text ""]
         Just loc ->
           let lat = toString loc.latitude
               lon = toString loc.longitude
           in [ text "Assuming you're near ",
                a [href ("https://www.google.com/maps?q="
                        ++ toString loc.latitude ++ "," -- maybe %2C
                        ++ toString loc.longitude)]
                  [text <| lat ++ "°N " ++ lon ++ "°W"]])

-- TODO account for this on the FAQ page
{-
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <style type="text/css">
    p.q {font-weight:bold;}
    a {text-decoration:underline;
      color: black;}
    body {text-align: left;
          padding-left: 200px;
          padding-bottom: 50px;
          padding-top: 50px;}
-}

faq : Html Msg
faq = div [] (List.map qAndA [
  ("Who made this site?",
   [a [href "http://xkcd.com/"] [ text "Randall Munroe"], text ", ", a [href "https://github.com/mmachenry/"] [ text "Mike MacHenry" ], text ", and ", a [href "https://github.com/presleyp/"] [text "Presley Pizzo" ]]),
  ("What does the number represent?",
   [text "The predicted accumulation in your area from the largest snowstorm you're expected to get during the next few days."]),
  ("Where do these forecasts come from?",
   [text "The US National Weather Service's ", a [href "http://www.hpc.ncep.noaa.gov/wwd/impactgraphics/"] [text "Short-Range Ensemble Forecast"], text " model."]),
  ("What if you got my location wrong?",
   [text "Sorry :("]),
  ("What if I want to see the forecast for a different location?",
   [text "Use a ", a [href "http://www.hpc.ncep.noaa.gov/wwd/winter_wx.shtml"] [ text "real weather site"], text "."]),
  ("What if I live outside the US?",
   [text "Use a real weather site."]),
  ("How can I find out when the snow is supposed to start?",
   [text "Use a real weather site."]),
  ("What if I want to see the forecast for a specific day?",
   [text "Use a real weather site."]),
  ("What if I want to know how much rain or ice I'm going to get?",
   [text "Use a real weather site."]),
  ("What if I want to know how many people are in space right now?",
   [text "Use ", a [href "http://www.howmanypeopleareinspacerightnow.com"] [text "How Many People Are In Space Right Now?"], text "."])
  ])

qAndA (question,answer) = div [] [
  p [ style [("font-weight", "bold")] ] [text "Q. ", text question ],
  p [ style [] ] (text "A. " :: answer)
  ]
