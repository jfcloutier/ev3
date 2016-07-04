module Perception.Update exposing (..)

import Dict exposing (Dict)
import Perception.Model as Model exposing (Model, Percept)

type Msg =
            AddPercept Percept

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    AddPercept percept ->
      ({model | percepts = Dict.insert percept.about percept.value model.percepts}, Cmd.none)
