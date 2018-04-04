module Main exposing (main)

import Html exposing (Html, p, text)
-- import Html.Attributes exposing ()
import Task
import Geolocation
import Json.Decode as Json
import Http

apiInvokeUrl = "https://5k9uziwo8k.execute-api.us-east-1.amazonaws.com/prod/get-info"

main =
  Html.program {
    init = init,
    update = update,
    subscriptions = subscriptions,
    view = view
  }

type Model =
    InitState
  | ErrorState String
  | LocationState Geolocation.Location
  | Snow SnowResult

type SnowResult = SnowResult String String

type Msg =
    UpdateLocation (Result Geolocation.Error Geolocation.Location)
  | UpdateSnow (Result Http.Error SnowResult)

init : (Model, Cmd Msg)
init = (InitState, Task.attempt UpdateLocation Geolocation.now)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  UpdateLocation (Ok loc) -> (model, getSnow loc)
  UpdateLocation (Err err) -> (ErrorState (toString err), Cmd.none)
  UpdateSnow (Ok x) -> (Snow x, Cmd.none)
  UpdateSnow (Err err) -> (ErrorState (toString err), Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none

view : Model -> Html Msg
view model = case model of
  InitState -> p [] [ text "Getting location..." ]
  ErrorState err -> p [] [ text (toString err) ]
  LocationState loc -> p [] [ text (toString loc) ]
  Snow sr -> p [] [ text (toString sr) ]

getSnow : Geolocation.Location -> Cmd Msg
getSnow loc =
  let url = apiInvokeUrl ++ "?"
            ++ "lat=" ++ toString loc.latitude
            ++ "&lon=" ++ toString loc.longitude
  in Http.send UpdateSnow (Http.get url decodeSnow)

decodeSnow : Json.Decoder SnowResult
decodeSnow =
  Json.map2 SnowResult
    (Json.field "coords" Json.string)
    (Json.field "inches" Json.string)
