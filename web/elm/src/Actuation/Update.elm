module Actuation.Update exposing (..)

import Actuation.Model as Model exposing (Model, IntentData)
import Dict exposing (Dict)

type Msg = 
  AddIntent IntentData
  
update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    AddIntent intentData ->
      ({model | intents = Dict.insert intentData.actuator (Model.intentFromData intentData) model.intents}, Cmd.none)

                
