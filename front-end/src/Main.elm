port module Main exposing (..)

import Browser
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

main = Browser.element {
    init = init,
    update = update,
    subscriptions = subscriptions,
    view = view
  }

type alias Geolocation = {
    latitude: Float,
    longitude: Float,
    timestamp: Time.Posix
    }

type alias Model = {
  location : Maybe (Result Http.Error Geolocation),
  prediction : Maybe (Result Http.Error PredictionData),
  debug : Bool,
  randomAmount : Float
  }

type alias Flags = {
  debug : Bool
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

initState flags = {
  location = Nothing,
  prediction = Nothing,
  debug = flags.debug,
  randomAmount = 0
  }

init : Flags -> (Model, Cmd Msg)
init flags = (initState flags, Random.generate UpdateRandom (Random.float 0 1))

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

view : Model -> Html Msg
view model =
  if model.debug
  then debugView model
  else normalView model

normalView model = div [style "font-weight" "bold",
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
  ++ metersToInchesStr (randomAmount, False) ++ Debug.toString err)]

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
     href "faq.html"]
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
    Nothing -> show model
    Just (Err _) -> show model
    Just (Ok loc) ->
      case model.prediction of
        Nothing -> show model
        Just (Err _) -> show model
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
               div [] [ text (Debug.toString loc) ],
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

show : Model -> Html Msg
show model = div [] [ text (Debug.toString model) ]
