module Actuation.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, attribute, classList)
import Actuation.Model as Model exposing (Model)
import Actuation.Update exposing (Msg)
import Dict exposing (Dict)


view:  Model -> Html Msg
view model =
  let
    getIntent actuator intents =
      Dict.get actuator intents |> Maybe.withDefault Model.defaultIntent
    strong_intent_about intent =
      if intent.strong then
        strong [] [text intent.about]
      else
        text intent.about
    viewIntent address intents actuator =
       tr []
           [
            td [] [
                   strong [] [text actuator]
                 , span [] [
                           text " did "
                          , strong_intent_about (getIntent actuator intents)
                          , text " "
                          , text (getIntent actuator intents).value]
                     ]
           ]
  in
    div []
        [
         h3 [] [text "Intents"]
        , table [classList [("table", True), ("table-bordered", True)]]
                  [
                   tbody []
                           (List.map (viewIntent address model.intents) (Dict.keys model.intents |> List.sort))
                  ]
        ]
