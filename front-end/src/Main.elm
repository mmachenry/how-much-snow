port module Main exposing (..)

import Browser exposing (..)
import Browser.Navigation as Nav
import Url exposing (Url)
import Html exposing (Html, p, text, div, a, span, h1, table, tr, td, th)
import Html.Attributes exposing (style, href)
import Task
import Json.Decode as Json
import Json.Encode
import Http
import Maybe.Extra exposing (isNothing)
import Time
import Iso8601
import List.Extra
import Random

inchesPerMeter = 39.3701
apiInvokeUrl =
  "https://oziaoyoi7f.execute-api.us-east-1.amazonaws.com/prod/prediction"

port updateLocation : (Json.Value -> msg) -> Sub msg

main = Browser.application {
    init = init,
    update = update,
    subscriptions = subscriptions,
    view = view,
    onUrlRequest = OnUrlRequest,
    onUrlChange = OnUrlChange
  }

type alias Geolocation = {
    latitude: Float,
    longitude: Float,
    timestamp: Time.Posix
    }

type alias Model = {
  navKey : Nav.Key,
  page : Page,
  location : Maybe (Result Http.Error Geolocation),
  prediction : Maybe (Result Http.Error PredictionData),
  randomAmount : Float
  }

type Page = Home | Debug | Faq | NotFound

type alias Flags = {
  }

type alias PredictionData = {
  data : List PredictionDatum
  }

type alias PredictionDatum = {
  latitude : Float,
  longitude : Float,
  distance : Float,
  metersofsnow : Float,
  predictedfor : Time.Posix
  }

type Msg =
    UpdateLocation Json.Value
  | UpdateSnow (Result Http.Error PredictionData)
  | UpdateRandom Float
  | OnUrlRequest UrlRequest
  | OnUrlChange Url

init : Flags -> Url -> Nav.Key -> (Model, Cmd Msg)
init flags url navKey = ({
  navKey = navKey,
  page = urlToPage url,
  location = Nothing,
  prediction = Nothing,
  randomAmount = 0
  },
  Random.generate UpdateRandom (Random.float 0 1))

subscriptions : Model -> Sub Msg
subscriptions _ = updateLocation UpdateLocation

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  UpdateLocation v -> case Json.decodeValue decodeLocation v of
    Ok loc -> ({model | location = Just (Ok loc)}, getSnow loc)
    Err str -> (model, Cmd.none)
  UpdateSnow result -> ({model | prediction = Just result}, Cmd.none)
  UpdateRandom n ->
    ({model | randomAmount = 2.718^(n*4)/inchesPerMeter}, Cmd.none)
  OnUrlRequest urlRequest ->
    case urlRequest of
      Internal url -> (model, Nav.pushUrl model.navKey (Url.toString url))
      External url -> (model, Nav.load url)
  OnUrlChange url -> ({ model | page = urlToPage url}, Cmd.none)

urlToPage : Url -> Page
urlToPage url = case url.path of
  "/" -> Home
  "/debug" -> Debug
  "/faq" -> Faq
  otherwise -> NotFound

getSnow : Geolocation -> Cmd Msg
getSnow loc = Http.get {
  url = apiInvokeUrl
          ++ "?lat=" ++ String.fromFloat loc.latitude
          ++ "&lon=" ++ String.fromFloat loc.longitude,
  expect = Http.expectJson UpdateSnow decodeSnow
  }

decodeLocation : Json.Decoder Geolocation
decodeLocation = Json.map3 Geolocation
  (Json.field "latitude" Json.float)
  (Json.field "longitude" Json.float)
  (Json.field "timestamp" (Json.map Time.millisToPosix Json.int))

decodeSnow : Json.Decoder PredictionData
decodeSnow = Json.map PredictionData (Json.field "data" decodeData)

decodeData : Json.Decoder (List PredictionDatum)
decodeData = Json.list decodePredictionDatum

decodePredictionDatum : Json.Decoder PredictionDatum
decodePredictionDatum =
  Json.map5 PredictionDatum
    (Json.field "latitude" Json.float)
    (Json.field "longitude" Json.float)
    (Json.field "distance" Json.float)
    (Json.field "metersofsnow" Json.float)
    (Json.field "millis" (Json.map Time.millisToPosix Json.int))

-----------------
-- Calculation --
-----------------

howMuchSnow : Time.Posix -> List PredictionDatum -> (Float, Bool)
howMuchSnow now data =
  let embelishedData = embelish now data
      uniqueInfluences =
        List.Extra.unique (List.map (\(_,i,_)->i) embelishedData)
      weightedPredictions = List.map weightPrediction embelishedData
  in (List.sum weightedPredictions / List.sum uniqueInfluences,
      isCurrentlySnowing embelishedData)

embelish :
     Time.Posix
  -> List PredictionDatum
  -> List (PredictionDatum, Float, Float)
embelish now data =
  let influences = List.map influenceByDistance data
      timesLeft = List.map (timeLeftAsOf now) data
  in List.Extra.zip3 data influences timesLeft

influenceByDistance : PredictionDatum -> Float
influenceByDistance datum = 1 / datum.distance^2

timeLeftAsOf : Time.Posix -> PredictionDatum -> Float
timeLeftAsOf now prediction =
  let timeDelta =
        Time.posixToMillis prediction.predictedfor - Time.posixToMillis now
      threeHours = 3*60*60*1000
  in min 1 (max 0 (toFloat timeDelta / toFloat threeHours))

weightPrediction : (PredictionDatum, Float, Float) -> Float
weightPrediction (datum, influence, timeRatio) =
  datum.metersofsnow * influence * timeRatio

isCurrentlySnowing : List (PredictionDatum, Float, Float) -> Bool
isCurrentlySnowing data =
  List.any
    (\(p, _, timeLeft)->
         p.metersofsnow > 0.01
      && timeLeft > 0
      && timeLeft < 1)
    data

----------
-- View --
----------

view : Model -> Browser.Document Msg
view model = {
  title = "How Much Snow Am I Going To Get?",
  body = [
    case model.page of
      Home -> homeView model
      Debug -> debugView model
      Faq -> faqView model
      NotFound -> errorMessage [text "Page not found"]
    ]
  }

homeView model = div [style "font-weight" "bold",
                        style "font-family" "Helvetica, sans-serif",
                        style "text-decoration" "none",
                        style "color" "black"] [
  case model.location of
    Nothing -> pendingMessage "Getting your location..."
    Just (Err err) -> noLocationError model.randomAmount
    Just (Ok loc) ->
      case model.prediction of
        Nothing -> pendingMessage "Getting prediction..."
        Just (Err err) -> noConnectionError err model.randomAmount
        Just (Ok prediction) ->
          case prediction.data of
            [] -> outOfRangeError model.randomAmount
            _ -> let now = loc.timestamp
                 in displayPrediction (howMuchSnow now prediction.data),
    footer model ]

verticalCenter : List (Html Msg) -> Html Msg
verticalCenter =
  div [
    style "text-align" "center",
    style "line-height" "70vh"]

pendingMessage : String -> Html Msg
pendingMessage message =
  verticalCenter [span [style "font-size" "8vw"] [text message]]

displayPrediction : (Float, Bool) -> Html Msg
displayPrediction (meters, currentlySnowing) =
  let outputStr = metersToInchesStr (meters, currentlySnowing)
      size = 80 / toFloat (String.length outputStr)
  in verticalCenter [
       span [style "font-size" (String.fromFloat size ++ "vw")]
            [text outputStr]]

metersToInchesStr : (Float, Bool) -> String
metersToInchesStr (meters, currentlySnowing) =
  let inches = meters * inchesPerMeter
  in if inches > 0.2 && inches <= 0.75
     then "Less than 1 " ++ unitWord (1, currentlySnowing)
     else let rounded = round inches
          in String.fromInt rounded ++ " " ++ unitWord (rounded, currentlySnowing)

unitWord : (Int, Bool) -> String
unitWord (rounded, currentlySnowing) =
  (if currentlySnowing then "more " else "")
  ++ if rounded == 1 then "inch" else "inches"

errorMessage : List (Html Msg) -> Html Msg
errorMessage =
  div [style "margin" "20vh 10vw 20vh 10vw",
       style "font-size" "3vw"]

noLocationError : Float -> Html Msg
noLocationError randomAmount = errorMessage [text (" Your device would not share its location with us. We cannot predict how much snow you will get if we don't know where you are. But we can give you a random number as a guess. Here you go: "
  ++ metersToInchesStr (randomAmount, False))]

noConnectionError : Http.Error -> Float -> Html Msg
noConnectionError err randomAmount = errorMessage [ text (" We were unable to connect to our snowy database. Maybe it's our fault, but please check your network and try again. In lieu of a network connection, here's a random number as a guess: "
  ++ metersToInchesStr (randomAmount, False))]

outOfRangeError : Float -> Html Msg
outOfRangeError randomAmount = errorMessage [ text (" Your location is outside the coverage area of the SREF model used by this site. If you would like it to be extended to cover you, please contact the US government. In the mean time, here's a random number as a guess: "
  ++ metersToInchesStr (randomAmount, False))]

footer model =
  div [style "position" "fixed",
       style "right" "2vw",
       style "bottom" "2vw",
       style "font-size" "1.8vw"]
      [ footerLocation model, faqLink ]

footerLocation model =
  span [style "color" "grey", style "text-decoration" "none"]
       (case model.location of
         Nothing -> [text ""]
         Just (Err _) -> [text ""]
         Just (Ok loc) ->
           let lat = String.fromFloat (roundTo 5 loc.latitude)
               lon = String.fromFloat (roundTo 5 loc.longitude)
           in [ text "Assuming you're near ",
                a [href ("https://www.google.com/maps?q="
                        ++ String.fromFloat loc.latitude ++ ","
                        ++ String.fromFloat loc.longitude)]
                  [text <| lat ++ "°N " ++ lon ++ "°W"],
                text " | "])

faqLink =
  a [style "font-weight" "bold",
     style "color" "grey",
     style "text-decoration" "none",
     href "/faq"]
    [text "More Information"]

roundTo : Int -> Float -> Float
roundTo d r =
  let order = toFloat (10^d)
  in toFloat (round (r * order)) / order

----------------
-- Debug view --
----------------

debugView : Model -> Html Msg
debugView model =
  case model.location of
    Nothing -> p [] [text "Getting location..."]
    Just (Err _) -> p [] [text "Location error!"]
    Just (Ok loc) ->
      case model.prediction of
        Nothing -> p [] [text "Getting prediction..."]
        Just (Err _) -> p [] [text "Prediction error!"]
        Just (Ok p) ->
          let now = loc.timestamp
              (metersOfSnow, currentlySnowing) = howMuchSnow now p.data
          in div [] [
               h1 [] [ text "Total" ],
               div [] [ text (String.fromFloat metersOfSnow
                              ++ " meters or "
                              ++ String.fromFloat(metersOfSnow * inchesPerMeter)
                              ++ " inches")],
               h1 [] [ text "Displayed as" ],
               div [] [ text (metersToInchesStr (metersOfSnow, currentlySnowing)) ],
               h1 [] [ text "Geolocation" ],
               div [] [ text (String.fromFloat loc.latitude ++ ", " ++ String.fromFloat loc.longitude) ],
               h1 [] [ text "Datetime from timestamp"],
               div [] [ text (Iso8601.fromTime now) ],
               h1 [] [ text "Data" ],
               table [] (
                   tr [] [
                   th [] [text "Latitude"],
                   th [] [text "Longitude"],
                   th [] [text "Distance"],
                   th [] [text "Meters of Snow"],
                   th [] [text "Predicted For"],
                   th [] [text "Influence"],
                   th [] [text "Time Left ratio"]
                   ] ::
                   (List.map tableRow (embelish now p.data)))
               ]

tableRow : (PredictionDatum, Float, Float) -> Html Msg
tableRow (prediction, influence, timeLeft) =
  let s = style "border" "1px solid black"
  in tr [] [
    td [s] [ text (String.fromFloat prediction.latitude)],
    td [s] [ text (String.fromFloat prediction.longitude)],
    td [s] [ text (String.fromFloat prediction.distance)],
    td [s] [ text (String.fromFloat prediction.metersofsnow)],
    td [s] [ text (Iso8601.fromTime prediction.predictedfor)],
    td [s] [ text (String.fromFloat influence)],
    td [s] [ text (String.fromFloat timeLeft)]
    ]

----------------
-- FAQ view --
----------------

faqView model = div [
    style "text-align" "left",
    style "padding-left" "15vw",
    style "padding-right" "15vw",
    style "padding-bottom" "10vh",
    style "padding-top" "10vh"
  ] [
  qna [text "Who made this site?"]
      [text "As with most software projects, this was a group effort. ",
       link "http://github.com/mmachenry/" "Mike MacHenry",
       text " contributed the consonants and ",
       link "https://github.com/presleyp/" "Presley Pizzo",
       text " was responsible for the vowels. All punctuation and spacing was generously donated by ",
       link "https://xkcd.com/" "Randall Munroe", text "."],
  qna [text "Where do these forecasts come from?"]
      [text "The US National Weather Service's ",
       link "http://www.spc.noaa.gov/exper/sref/srefplumes/?PRM=Total-SNO" "Short-Range Ensemble Forecast",
       text " model."],
  qna [text "What does the number represent?"]
      [text "An estimate of much snow you're going to get over the next few days."],
  qna [text "Starting when? What if it's already snowing?"]
      [text "Starting now, the moment you refresh the page. The number only includes future snowfall, not snow already on the ground."],
  qna [text "Why don't you include the snow that's already on the ground?"]
      [text "We don't know how much snow is on the ground."],
  qna [text "Why not?"]
      [text "It's complicated. In some ways, the future is easier to consistently measure than the past."],
  qna [text "What?"]
      [text "Never mind."],
  qna [text "What if you got my location wrong?"]
      [text "Sorry :("],
  rws "What if I want to see the forecast for a different location?"
      "https://www.weather.gov/",
  rws "What if I live outside the US?"
      "https://www.wunderground.com/",
  rws "How can I find out when the snow is supposed to start?"
      "http://www.spc.noaa.gov/exper/sref/srefplumes/",
  rws "What if I want to see the forecast for a specific day?"
      "https://weather.us/",
  rws "What if I want to know how much rain or ice I'm going to get?"
      "http://www.wpc.ncep.noaa.gov/wwd/winter_wx.shtml",
  qna [text "What if I want to know how many people are in space right now?"]
      [text "Use ", link "http://www.howmanypeopleareinspacerightnow.com" "How Many People Are In Space Right Now?", text "."],
  qna [text "Is it Christmas?"]
      [text "No. (99.73% accurate)"],
  div [style "position" "fixed",
       style "right" "15px",
       style "bottom" "15px"]
      [a [style "font-weight" "bold",
          style "color" "grey",
          style "text-decoration" "none",
          href "/"]
         [text "How Much Snow Am I Going To Get?"]]
  ]

qna q a = div [] [
  p [style "font-weight" "bold"] (text "Q. " :: q),
  p [] (text "A. " :: a)
  ]

rws q l = qna [text q]
      [text "A. Use a ", link l "real weather site", text "."]

link l t = a [href l, style "text-decoration" "underline", style "color" "black"] [text t]
