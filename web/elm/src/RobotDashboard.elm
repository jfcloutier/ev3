port module RobotDashboard exposing (..)

import Html.App as App
import Dashboard.Model exposing (Model)
import Dashboard.Update exposing (Msg)
import Dashboard.View
import Status.Update
import Perception.Update
import Motivation.Update
import Comportment.Update
import Actuation.Update
import Status.Model
import Perception.Model
import Motivation.Model
import Comportment.Model
import Actuation.Model

main : Program Never
main =
  App.program
          {init = Dashboard.Update.init
           , update = Dashboard.Update.update
           , view = Dashboard.View.view
           , subscriptions = subscriptions
          }

-- Subscriptions

subscriptions : Model -> Sub Msg
subscriptions model =
  let
    subs =
      [
       (Dashboard.Update.StatusMsg << Status.Update.SetRuntimeStats) |> runtimeStatsPort
      , (Dashboard.Update.StatusMsg << Status.Update.SetActive) |> activeStatePort
      , (Dashboard.Update.PerceptionMsg << Perception.Update.AddPercept) |> perceptPort
      , (Dashboard.Update.MotivationMsg << Motivation.Update.SetMotive) |> motivePort
      , (Dashboard.Update.ComportmentMsg << Comportment.Update.SetBehavior) |> behaviorPort
      , (Dashboard.Update.ComportmentMsg << Comportment.Update.ReviveAll) |> activeStatePort
      , (Dashboard.Update.ActuationMsg << Actuation.Update.AddIntent) |> intentPort
      ]
    in
      Sub.batch subs

-- PORTS

-- status
port runtimeStatsPort: (Status.Model.RuntimeStats -> msg) -> Sub msg
port activeStatePort: (Status.Model.ActiveState -> msg) -> Sub msg

-- perception
port perceptPort: (Perception.Model.Percept -> msg) -> Sub msg

-- motivation
port motivePort: (Motivation.Model.Motive -> msg) -> Sub msg

-- behavior
port behaviorPort: (Comportment.Model.BehaviorData -> msg) -> Sub msg

-- intent
port intentPort: (Actuation.Model.IntentData -> msg) -> Sub msg
