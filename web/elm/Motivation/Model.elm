module Motivation.Model where

import Dict exposing (Dict)

type alias Model = {motives: Dict String Motive}                   
type alias Motive = {about: String, on: Bool, inhibited: Bool}

initialModel: Model
initialModel =
  {motives = Dict.empty}

defaultMotive: Motive
defaultMotive =
  Motive "" False False
