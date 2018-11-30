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

apiInvokeUrl = "https://oziaoyoi7f.execute-api.us-east-1.amazonaws.com/prod/prediction"

main =
  Html.programWithFlags {
    init = init,
    update = update,
    subscriptions = (\_->Sub.none),
    view = view
  }

type alias Model = {
  location : Maybe Geolocation.Location,
  prediction : Maybe PredictionData,
  errorMessage : Maybe String,
  debug : Bool
  }

type alias Flags = {
  debug : Bool
  }

type alias PredictionData = {
  meters : Float,
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

initState flags = {
  location = Nothing,
  prediction = Nothing,
  errorMessage = Nothing,
  debug = flags.debug
  }

init : Flags -> (Model, Cmd Msg)
init flags = (initState flags, Task.attempt UpdateLocation Geolocation.now)

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
            ++ "?lat=" ++ toString loc.latitude
            ++ "&lon=" ++ toString loc.longitude
  in Http.send UpdateSnow (Http.get url decodeSnow)

decodeSnow : Json.Decoder PredictionData
decodeSnow =
  Json.map2
    PredictionData
      (Json.field "meters" Json.float)
      (Json.field "data" decodeData)

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

howMuchSnow : DateTime -> List PredictionDatum -> Float
howMuchSnow now data =
  let embelishedData = embelish now data
      uniqueInfluences =
        List.Extra.unique (List.map (\(_,i,_)->i) embelishedData)
      weightedPredictions = List.map weightPrediction embelishedData
  in List.sum weightedPredictions / List.sum uniqueInfluences

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
  let delta = Time.DateTime.delta now prediction.predictedfor
      minutes = delta.days * 24*60 + delta.hours * 60 + delta.minutes
      threeHours = 3*60
  in if minutes <= 0
     then 1
     else if minutes > threeHours
          then 0
          else 1 - toFloat minutes / threeHours

weightPrediction : (PredictionDatum, Float, Float) -> Float
weightPrediction (datum, influence, timeRatio) =
  datum.metersofsnow * influence * timeRatio

----------
-- View --
----------

view : Model -> Html Msg
view model =
  if model.debug
  then debugView model
  else div [] [ mainText model, footer model]

mainText model = case model.errorMessage of
  Just str -> displayError str
  Nothing ->
    div [style [("font-weight", "bold"),
                ("font-family", "Helvetica, sans-serif"),
                ("text-decoration", "none"),
                ("color", "black"),
                ("text-align", "center"),
                ("line-height", "80vh")]] [
      case model.location of
        Nothing -> pendingMessage "Getting your location..."
        Just loc ->
          case model.prediction of
            Nothing -> pendingMessage "Getting prediction..."
            Just p -> displayPrediction p.meters
      ]

debugView : Model -> Html Msg
debugView model =
  case model.location of
    Nothing -> show model
    Just loc ->
      case model.prediction of
        Nothing -> show model
        Just p ->
          let now = Time.DateTime.fromTimestamp loc.timestamp
          in div [] [
               h1 [] [ text "Total" ],
               div [] [ text (toString (howMuchSnow now p.data)) ],
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

displayError : String -> Html Msg
displayError message = p [] [text message]

pendingMessage : String -> Html Msg
pendingMessage message = span [style [("font-size", "8vw")]] [text message]

displayPrediction : Float -> Html Msg
displayPrediction meters =
    let inches = round (meters * 39.3701)
        unitWord = if inches == 1 then "inch" else "inches"
    in span [style [("font-size", "18vw")]]
                   [text (toString inches ++ " " ++ unitWord)]

footer model =
  div [style [("position", "fixed"),
              ("right", "2vw"),
              ("bottom", "2vw"),
              ("font-size", "3vw")]]
      [ footerLocation model, text " | ", faqLink ]

faqLink =
  a [style [("font-weight", "bold"), ("color", "grey"),
            ("text-decoration", "none")],
     href "faq.html"]
    [text "More Information"]

footerLocation model =
  span [style [("color", "grey"), ("text-decoration", "none")]]
       (case model.location of
         Nothing -> [text ""]
         Just loc ->
           let lat = toString (roundTo 5 loc.latitude)
               lon = toString (roundTo 5 loc.longitude)
           in [ text "Assuming you're near ",
                a [href ("https://www.google.com/maps?q="
                        ++ toString loc.latitude ++ ","
                        ++ toString loc.longitude)]
                  [text <| lat ++ "°N " ++ lon ++ "°W"]])

roundTo : Int -> Float -> Float
roundTo d r =
  let order = toFloat (10^d)
  in toFloat (round (r * order)) / order
