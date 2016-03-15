module Perception.Model where

import Dict exposing (Dict)

type alias Model = {percepts: Dict String String}
                 
type alias Percept = {about: String, value: String}

initialModel: Model
initialModel =
  {percepts = Dict.empty}
