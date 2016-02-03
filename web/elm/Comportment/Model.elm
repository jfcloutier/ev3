module Comportment.Model where

import Dict exposing (Dict)

type alias Model = {behaviors: Dict String Behavior}
type alias BehaviorData = {name: String, event: String, value: String}
type alias Behavior = {name: String, started: Bool, inhibited: Bool, overwhelmed: Bool, state: String}

initialModel: Model
initialModel =
  {behaviors = Dict.empty}

defaultBehavior: Behavior
defaultBehavior =
  Behavior "" False False False ""
