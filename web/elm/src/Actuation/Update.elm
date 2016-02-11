module Actuation.Update where

import Actuation.Model as Model exposing (Model, IntentData)
import Dict exposing (Dict)
import Effects exposing (Effects)

type Action = 
  AddIntent IntentData
  
update: Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    AddIntent intentData ->
      ({model | intents = Dict.insert intentData.actuator (Model.intentFromData intentData) model.intents}, Effects.none)

                
