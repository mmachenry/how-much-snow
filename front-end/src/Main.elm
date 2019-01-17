module Main exposing (..)

import Html exposing (Html, p, text, div, a, span, h1, table, tr, td, th)
import Html.Attributes exposing (style, href)
import Task
import Geolocation
import Json.Decode as Json
import Json.Encode
import Http
import Maybe.Extra exposing (isNothing)
import Time exposing (Time)
import Time.DateTime exposing (DateTime)
import Time.Iso8601
import List.Extra
import Random

inchesPerMeter = 39.3701
apiInvokeUrl =
  "https://oziaoyoi7f.execute-api.us-east-1.amazonaws.com/prod/prediction"

main =
  Html.programWithFlags {
    init = init,
    update = update,
    subscriptions = (\_->Sub.none),
    view = view
  }

type alias Model = {
  location : Maybe (Result Geolocation.Error Geolocation.Location),
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
  predictedfor : DateTime
  }

type Msg =
    UpdateLocation (Result Geolocation.Error Geolocation.Location)
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

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  UpdateLocation result -> (
    {model | location = Just result},
    case result of
      Ok loc -> getSnow loc
      Err err -> Cmd.none)
  UpdateSnow result -> ({model | prediction = Just result}, Cmd.none)
  UpdateRandom n ->
    ({model | randomAmount = 2.718^(n*4)/inchesPerMeter},
     Task.attempt UpdateLocation Geolocation.now)

getSnow : Geolocation.Location -> Cmd Msg
getSnow loc =
  let url = apiInvokeUrl
            ++ "?lat=" ++ toString loc.latitude
            ++ "&lon=" ++ toString loc.longitude
  in Http.send UpdateSnow (Http.get url decodeSnow)

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
    (Json.field "predictedfor" decodeISO8601)

decodeISO8601 : Json.Decoder DateTime
decodeISO8601 =
  let mapError r = case r of
        Ok dt -> Json.succeed dt
        Err str -> Json.fail "Invalid date"
      replaceSpace input = String.join "T" (String.split " " input)
  in Json.string
     |> Json.map replaceSpace
     |> Json.map Time.Iso8601.toDateTime
     |> Json.andThen mapError

-----------------
-- Calculation --
-----------------

howMuchSnow : DateTime -> List PredictionDatum -> (Float, Bool)
howMuchSnow now data =
  let embelishedData = embelish now data
      uniqueInfluences =
        List.Extra.unique (List.map (\(_,i,_)->i) embelishedData)
      weightedPredictions = List.map weightPrediction embelishedData
  in (List.sum weightedPredictions / List.sum uniqueInfluences,
      isCurrentlySnowing embelishedData)

embelish :
     DateTime
  -> List PredictionDatum
  -> List (PredictionDatum, Float, Float)
embelish now data =
  let influences = List.map influence data
      timesLeft = List.map (timeLeft now) data
  in List.Extra.zip3 data influences timesLeft

influence : PredictionDatum -> Float
influence datum = 1 / datum.distance^2

timeLeft : DateTime -> PredictionDatum -> Float
timeLeft now prediction =
  let timeDelta = Time.DateTime.delta prediction.predictedfor now
      threeHours = 3*60
  in min 1 (max 0 (toFloat timeDelta.minutes / threeHours))

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

normalView model = div [style [("font-weight", "bold"),
                               ("font-family", "Helvetica, sans-serif"),
                               ("text-decoration", "none"),
                               ("color", "black")]] [
  case model.location of
    Nothing -> pendingMessage "Getting your location..."
    Just (Err err) -> noLocationError model.randomAmount
    Just (Ok loc) ->
      case model.prediction of
        Nothing -> pendingMessage "Getting prediction..."
        Just (Err err) -> noConnectionError model.randomAmount
        Just (Ok prediction) ->
          case prediction.data of
            [] -> outOfRangeError model.randomAmount
            _ -> let now = Time.DateTime.fromTimestamp loc.timestamp
                 in displayPrediction (howMuchSnow now prediction.data),
    footer model ]

verticalCenter : List (Html Msg) -> Html Msg
verticalCenter =
  div [style [ ("text-align", "center"),
               ("line-height", "70vh")]]

pendingMessage : String -> Html Msg
pendingMessage message =
  verticalCenter [span [style [("font-size", "8vw")]] [text message]]

displayPrediction : (Float, Bool) -> Html Msg
displayPrediction (meters, currentlySnowing) =
  let outputStr = metersToInchesStr (meters, currentlySnowing)
      size = 80 / toFloat (String.length outputStr)
  in verticalCenter [
       span [style [("font-size", toString size ++ "vw")]]
            [text outputStr]]

metersToInchesStr : (Float, Bool) -> String
metersToInchesStr (meters, currentlySnowing) =
  let inches = meters * inchesPerMeter
  in if inches > 0.2 && inches <= 0.75
     then "Less than 1 " ++ unitWord (1, currentlySnowing)
     else let rounded = round inches
          in toString rounded ++ " " ++ unitWord (rounded, currentlySnowing)

unitWord : (Int, Bool) -> String
unitWord (rounded, currentlySnowing) =
  (if currentlySnowing then "more " else "")
  ++ if rounded == 1 then "inch" else "inches"

errorMessage : List (Html Msg) -> Html Msg
errorMessage =
  div [style [("margin", "20vh 10vw 20vh 10vw"),
              ("font-size", "3vw")]]

noLocationError : Float -> Html Msg
noLocationError randomAmount = errorMessage [text (" Your device would not share its location with us. We cannot predict how much snow you will get if we don't know where you are. But we can give you a random number as a guess. Here you go: "
  ++ metersToInchesStr (randomAmount, False))]

noConnectionError : Float -> Html Msg
noConnectionError randomAmount = errorMessage [ text (" We were unable to connect to our snowy database. Maybe it's our fault, but please check your network and try again. In lieu of a network connection, here's a random number as a guess: "
  ++ metersToInchesStr (randomAmount, False))]

outOfRangeError : Float -> Html Msg
outOfRangeError randomAmount = errorMessage [ text (" Your location is outside the coverage area of the SREF model used by this site. If you would like it to be extended to cover you, please contact the US government. In the mean time, here's a random number as a guess: "
  ++ metersToInchesStr (randomAmount, False))]

footer model =
  div [style [("position", "fixed"),
              ("right", "2vw"),
              ("bottom", "2vw"),
              ("font-size", "1.8vw")]]
      [ footerLocation model, faqLink ]

footerLocation model =
  span [style [("color", "grey"), ("text-decoration", "none")]]
       (case model.location of
         Nothing -> [text ""]
         Just (Err _) -> [text ""]
         Just (Ok loc) ->
           let lat = toString (roundTo 5 loc.latitude)
               lon = toString (roundTo 5 loc.longitude)
           in [ text "Assuming you're near ",
                a [href ("https://www.google.com/maps?q="
                        ++ toString loc.latitude ++ ","
                        ++ toString loc.longitude)]
                  [text <| lat ++ "°N " ++ lon ++ "°W"],
                text " | "])

faqLink =
  a [style [("font-weight", "bold"),
            ("color", "grey"),
            ("text-decoration", "none")],
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
          let now = Time.DateTime.fromTimestamp loc.timestamp
              (metersOfSnow, currentlySnowing) = howMuchSnow now p.data
          in div [] [
               h1 [] [ text "Total" ],
               div [] [ text (toString metersOfSnow
                              ++ " meters or "
                              ++ toString(metersOfSnow * inchesPerMeter)
                              ++ " inches")],
               h1 [] [ text "Displayed as" ],
               div [] [ text (metersToInchesStr (metersOfSnow, currentlySnowing)) ],
               h1 [] [ text "Geolocation" ],
               div [] [ text (toString loc) ],
               h1 [] [ text "Datetime from timestamp"],
               div [] [ text (Time.Iso8601.fromDateTime now) ],
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
  let s = style [("border","1px solid black")]
  in tr [] [
    td [s] [ text (toString prediction.latitude)],
    td [s] [ text (toString prediction.longitude)],
    td [s] [ text (toString prediction.distance)],
    td [s] [ text (toString prediction.metersofsnow)],
    td [s] [ text (Time.Iso8601.fromDateTime prediction.predictedfor)],
    td [s] [ text (toString influence)],
    td [s] [ text (toString timeLeft)]
    ]

show : Model -> Html Msg
show model = div [] [ text (toString model) ]
