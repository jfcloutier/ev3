module Dashboard.View exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (class, attribute, classList)
import Dashboard.Model exposing (Model)
import Dashboard.Update exposing (Msg)
import Status.View
import Perception.View
import Motivation.View
import Comportment.View
import Actuation.View

view:  Model -> Html Msg
view  model =
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
                div [class "col-lg-12"] [App.map Dashboard.Update.StatusMsg (Status.View.view model.status)]
               ]
       , div [class "row"]
               [
                div [class "col-lg-3"] [App.map Dashboard.Update.PerceptionMsg (Perception.View.view model.perception)]
               , div [class "col-lg-2"] [App.map Dashboard.Update.MotivationMsg (Motivation.View.view model.motivation)]
               , div [class "col-lg-3"] [App.map Dashboard.Update.ComportmentMsg (Comportment.View.view model.comportment)]
               , div [class "col-lg-4"] [App.map Dashboard.Update.ActuationMsg (Actuation.View.view model.actuation)]
               ]
       ]

