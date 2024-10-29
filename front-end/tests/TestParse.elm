module TestParse exposing (..)

import Expect
import Test exposing (..)
import Json.Decode as Json
import Time
import Iso8601

type alias PredictionDatum = {
  predictedfor : Time.Posix
  }

suite : Test
suite =
  test "Parses an example"
    (\_-> Expect.equal
            (Json.decodeString decodePredictionDatum s)
            (Ok {predictedfor=Time.millisToPosix 0}))

decodePredictionDatum : Json.Decoder PredictionDatum
decodePredictionDatum =
  Json.map PredictionDatum
    (Json.field "predictedfor" Iso8601.decoder)

s = """
    {
      "predictedfor": "2020-12-16T06:00:00.000Z"
    }
"""
