module RobotDashboard where

import Effects exposing (Never)
import StartApp
import Task exposing (Task)
import Html exposing (Html)
import App.Model exposing (Model)
import App.Update exposing (Action)
import App.View
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

app: StartApp.App Model
app =
  StartApp.start
          {init = App.Update.init
           , update = App.Update.update
           , view = App.View.view
           , inputs = inputs
          }

main : Signal Html
main =
  app.html


-- INPUTS

inputs: List (Signal Action)
inputs =
  [
    Signal.map(App.Update.StatusAction << Status.Update.SetRuntimeStats) runtimeStatsPort
  , Signal.map(App.Update.StatusAction << Status.Update.SetActive) activeStatePort
  , Signal.map(App.Update.PerceptionAction << Perception.Update.AddPercept) perceptPort
  , Signal.map(App.Update.MotivationAction << Motivation.Update.SetMotive) motivePort
  , Signal.map(App.Update.ComportmentAction << Comportment.Update.SetBehavior) behaviorPort
  , Signal.map(App.Update.ComportmentAction << Comportment.Update.ReviveAll) activeStatePort
  , Signal.map(App.Update.ActuationAction << Actuation.Update.AddIntent) intentPort
  ]

-- PORTS

port tasks : Signal (Task Never ()) 
port tasks =
  app.tasks -- From effects

-- status
port runtimeStatsPort: Signal Status.Model.RuntimeStats
port activeStatePort: Signal Status.Model.ActiveState

-- perception
port perceptPort: Signal Perception.Model.Percept

-- motivation
port motivePort: Signal Motivation.Model.Motive

-- behavior
port behaviorPort: Signal Comportment.Model.BehaviorData

-- intent
port intentPort: Signal Actuation.Model.IntentData
