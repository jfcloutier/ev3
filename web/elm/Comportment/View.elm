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
      Dict.get name behaviors |> Maybe.withDefault Model.defaultBehavior
    inhibitedText bool name =
      if bool then
        node "s" [] [text name]
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
    viewBehavior address behaviors name =
      let
        behavior = getBehavior name behaviors
      in
        tr []
             [
              td [] [
                    strong [class(statusClass behavior)] [inhibitedText (behavior.inhibited) name]
                   , span [] [text " is ", text (behavior.state)]
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

