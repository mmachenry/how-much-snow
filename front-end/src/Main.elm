module Main exposing (..)

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

initState = { location = Nothing, prediction = Nothing, errorMessage = Nothing}

init : (Model, Cmd Msg)
init = (initState, Task.attempt UpdateLocation Geolocation.now)

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
view model = div [] [ mainText model, footer model]

mainText model = case model.errorMessage of
  Just str -> displayError str
  Nothing ->
    div [style [("display", "flex"),
                ("height", "100vh"),
                ("justify-content", "center"),
                ("align-items", "center")]] [
      span [style [("font-weight", "bold"),
                   ("font-family", "Helvetica, sans-serif"),
                   ("text-decoration", "none"),
                   ("color", "black")]] [
           case model.location of
              Nothing -> pendingMessage "Getting your location..."
              Just _ ->
                case model.prediction of
                  Nothing -> pendingMessage "Getting prediction..."
                  Just p -> displayPrediction p ]]

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
