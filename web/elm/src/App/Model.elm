module App.Model where

import Status.Model
import Perception.Model
import Motivation.Model
import Comportment.Model
import Actuation.Model


type alias Model =
  {status: Status.Model.Model
  , perception: Perception.Model.Model
  , motivation: Motivation.Model.Model
  , comportment: Comportment.Model.Model
  , actuation: Actuation.Model.Model
  }

initialModel : Model
initialModel =
  {status = Status.Model.initialModel
    , perception = Perception.Model.initialModel
    , motivation = Motivation.Model.initialModel
    , comportment = Comportment.Model.initialModel
    , actuation = Actuation.Model.initialModel
   }
