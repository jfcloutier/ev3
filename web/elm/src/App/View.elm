module App.View where

import Html exposing (..)
import Html.Attributes exposing (class, attribute, classList)
import App.Model exposing (Model)
import App.Update exposing (Action)
import Status.View
import Perception.View
import Motivation.View
import Comportment.View
import Actuation.View

view: Signal.Address Action -> Model -> Html
view address model =
  let
    statusAddress =
      Signal.forwardTo address App.Update.StatusAction

    perceptionAddress =
      Signal.forwardTo address App.Update.PerceptionAction

    motivationAddress =
      Signal.forwardTo address App.Update.MotivationAction

    comportmentAddress =
      Signal.forwardTo address App.Update.ComportmentAction

    actuationAddress =
      Signal.forwardTo address App.Update.ActuationAction
  in
  div[class "container-fluid", attribute "role" "main"]
       [div [class "row"]
        [
         div [class "col-lg-12"]
               [
                h1 [classList [("text-center", True), ("bg-primary", True)]] [text "Robot Dashboard"]
               ]
        ]
       , div [class "row"]
               [
                div [class "col-lg-12"] [Status.View.view statusAddress model.status]
               ]
       , div [class "row"]
               [
                div [class "col-lg-3"] [Perception.View.view perceptionAddress model.perception]
               , div [class "col-lg-2"] [Motivation.View.view motivationAddress model.motivation]
               , div [class "col-lg-3"] [Comportment.View.view comportmentAddress model.comportment]
               , div [class "col-lg-4"] [Actuation.View.view actuationAddress model.actuation]
               ]
       ]

