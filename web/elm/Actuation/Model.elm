module Actuation.Model where

import Dict exposing (Dict)

type alias Model = {intents: Dict String Intent}
type alias IntentData = {actuator: String, about: String, value: String, strong: Bool}
type alias Intent = {about: String, value: String, strong: Bool}
                  
initialModel: Model
initialModel =
  {intents = Dict.empty}

defaultIntent: Intent
defaultIntent =
  Intent "" "" False

intentFromData: IntentData -> Intent
intentFromData intentData =
  Intent intentData.about intentData.value intentData.strong

