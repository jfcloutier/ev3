module Comportment.Model exposing (..)

import Dict exposing (Dict)

type alias Model = {behaviors: Dict String Behavior}
type alias BehaviorData = {name: String, reflex: Bool, event: String, value: String}
type alias Behavior = {name: String, started: Bool, reflex: Bool, inhibited: Bool, overwhelmed: Bool, state: String}

initialModel: Model
initialModel =
  {behaviors = Dict.empty}

defaultBehavior: String -> Behavior
defaultBehavior name =
  Behavior name False False False False ""
