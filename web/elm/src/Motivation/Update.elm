module Motivation.Update exposing (..)

import Dict exposing (Dict)
import Motivation.Model as Model exposing (Model, Motive)

type Msg =
  SetMotive Motive

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SetMotive motive ->
      ({model | motives = Dict.insert motive.about motive model.motives}, Cmd.none)
