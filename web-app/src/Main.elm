module Main exposing (main)

import Html exposing (Html, p, text, div, a, span)
import Html.Attributes exposing (style, href)
import Task
import Geolocation
import Json.Decode as Json
import Json.Encode
import Http
import Maybe.Extra exposing (isNothing)

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
  prediction : Maybe Float,
  errorMessage : Maybe String
  }

type Msg =
    UpdateLocation (Result Geolocation.Error Geolocation.Location)
  | UpdateSnow (Result Http.Error Float)

{-
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
-}

initState = { location = Nothing, prediction = Nothing, errorMessage = Nothing}

init : (Model, Cmd Msg)
init = (initState, Task.attempt UpdateLocation Geolocation.now)
--init = (initState, spoofMessage (UpdateLocation (Ok testLocation)))

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

decodeSnow : Json.Decoder Float
decodeSnow = Json.field "meters" Json.float

view : Model -> Html Msg
view model =
  div [style [("text-align", if isNothing model.prediction
                             then "left" else "center"),
              ("padding-top", "200px"),
              ("padding-left", "100px"),
              ("padding-right", "100px")]]
      [(case model.errorMessage of
          Just str -> p [] [text str]
          Nothing -> span [style [("font-weight", "bold"),
                                  ("font-size", if isNothing model.prediction
                                                then "80pt" else "120pt"),
                                  ("font-family", "Helvetica, sans-serif"),
                                  ("text-decoration", "none"),
                                  ("color", "black")]]
                          (case model.location of
                             Nothing -> [text "Getting your location..."]
                             Just _ ->
                               case model.prediction of
                                 Nothing -> [text "Getting prediction..."]
                                 Just p -> [ displayPrediction p ])),
        footer model]

displayPrediction : Float -> Html Msg
displayPrediction meters =
    let inches = round (meters * 39.3701)
        unitWord = if inches == 1 then "inch" else "inches"
    in text (toString inches ++ " " ++ unitWord)

footer model =
  div [style [("position", "fixed"), ("right", "15px"), ("bottom", "15px")]]
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
           let lat = toString loc.latitude
               lon = toString loc.longitude
           in [ text "Assuming you're near ",
                a [href ("https://www.google.com/maps?q="
                        ++ toString loc.latitude ++ ","
                        ++ toString loc.longitude)]
                  [text <| lat ++ "°N " ++ lon ++ "°W"]])
