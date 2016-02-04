module Status.View where

import Html exposing (..)
import Html.Attributes exposing (class, attribute, classList)
import Html.Events exposing (onClick)
import Status.Update exposing (Action)
import Status.Model as Model exposing (Model)

view: Signal.Address Action -> Model -> Html
view address model =
    let
      pausingLabel model =
        if not model.paused then
          "Pause"
        else
          "Resume"
      btnColor paused =
        if not paused then
          "btn-success"
        else
          "btn-danger"
      over value threshold =
        if value < threshold then
          "danger"
        else
          "success"
      swapUsed value =
        if value > 0 then
          "danger"
        else
          "success"
      src active =
        if active then
          "/images/active.png"
        else
          "/images/fainted.png"
    in
      div [class "container-fluid"]
          [
      div [class "row"]
                   [
                    div [class "col-lg-2"]
                          [
                           button
                           [onClick address Status.Update.TogglePaused
                           , classList [ ("btn", True), ((btnColor model.paused), True)]]
                           [text (pausingLabel model)]
                          ]
                   , div [class "col-lg-2"]
                           [
                            img [attribute "src" (src model.active)] []
                           ]
                   , div [class "col-lg-8"]
                           [
                            table [classList [("table", True), ("table-bordered", True)]]
                                    [
                                     thead []
                                             [
                                              th [] [text "RAM free (M)"]
                                             , th [] [text " RAM used (M)"]
                                             , th [] [text " Swap free (M)"]
                                             , th [] [text " Swap used (M)"]
                                             ]
                                    , tbody []
                                              [
                                               tr []
                                                    [
                                                     td [class (over model.runtime.ramFree 10)] [text (toString model.runtime.ramFree)]
                                                    , td [] [text (toString model.runtime.ramUsed)]
                                                    , td [class (over model.runtime.swapFree 10)] [text (toString model.runtime.swapFree)]
                                                    , td [class (swapUsed model.runtime.swapUsed)] [text (toString model.runtime.swapUsed)]
                                                    ]
                                              ]
                                    ]
                           ]  
                   ]
    ]
