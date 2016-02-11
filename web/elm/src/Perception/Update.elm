module Perception.Update where

import Dict exposing (Dict)
import Effects exposing (Effects)
import Perception.Model as Model exposing (Model, Percept)

type Action =
            AddPercept Percept

update: Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    AddPercept percept ->
      ({model | percepts = Dict.insert percept.about percept.value model.percepts}, Effects.none)
