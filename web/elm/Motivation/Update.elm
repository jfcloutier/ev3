module Motivation.Update where

import Dict exposing (Dict)
import Effects exposing (Effects)
import Motivation.Model as Model exposing (Model, Motive)

type Action =
  SetMotive Motive

update: Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SetMotive motive ->
      ({model | motives = Dict.insert motive.about motive model.motives}, Effects.none)
