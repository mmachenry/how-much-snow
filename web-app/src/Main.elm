module Main exposing (main)

import Html exposing (Html, p, text)
-- import Html.Attributes exposing ()
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

testLocation = {
  latitude = 42.401981,
  longitude = -71.122687,
  accuracy = 0,
  altitude = Nothing,
  movement = Nothing,
  timestamp = 0
  }

init : (Model, Cmd Msg)
--init = (InitState, Task.attempt UpdateLocation Geolocation.now)
init = (InitState, getSnow testLocation)

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
  let url = apiInvokeUrl ++ "?lat=" ++ toString (loc.latitude) ++
            "&lon=" ++ toString (loc.longitude)
  in Http.send UpdateSnow (Http.get apiInvokeUrl decodeSnow)

decodeSnow : Json.Decoder SnowResult
decodeSnow =
  Json.map2 SnowResult
    (Json.field "coords" Json.string)
    (Json.field "inches" Json.string)
