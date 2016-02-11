module Comportment.View where

import Html exposing (..)
import Html.Attributes exposing (class, attribute, classList)
import Comportment.Model as Model exposing (Model)
import Comportment.Update exposing (Action)
import Dict exposing (Dict)

view: Signal.Address Action -> Model -> Html
view address model =
  let
    getBehavior name behaviors =
      Dict.get name behaviors |> Maybe.withDefault (Model.defaultBehavior name)
    formattedText inhibited reflex name =
      if inhibited then
        node "s" [] [text name]
      else
        if reflex then
          em [] [text name]
        else
          text name
    statusClass behavior =
      if behavior.started then
        if behavior.overwhelmed then
          "bg-warning"
        else
          "bg-success"
      else
        "bg-danger"
    is_or_reacted reflex =
      if reflex then
        " reacted to "
      else
        " is "
    viewBehavior address behaviors name =
      let
        behavior = getBehavior name behaviors
      in
        tr []
             [
              td [] [
                    strong [class (statusClass behavior)] [formattedText behavior.inhibited behavior.reflex name]
                   , span [] [text (is_or_reacted behavior.reflex),  text (behavior.state)]
                   ]
             ]
  in
    div []
        [
         h3 [] [text "Behaviors"]
        , table [classList [("table", True), ("table-bordered", True)]]
                  [
                   tbody []
                           (List.map (viewBehavior address model.behaviors) (Dict.keys model.behaviors |> List.sort))
                  ]
        ]

