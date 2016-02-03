module Perception.View where

import Html exposing (..)
import Html.Attributes exposing (class, attribute, classList)
import Perception.Model as Model exposing (Model)
import Perception.Update exposing (Action)
import Dict exposing (Dict)

view: Signal.Address Action -> Model -> Html
view address model =
  let
    getValue about percepts =
      Dict.get about percepts |> Maybe.withDefault "?"
    viewPercept address percepts about =
       tr []
           [
            td [] [
                   strong [] [text about]
                 , span [] [text " is ", text (getValue about percepts)]
                     ]
           ]
  in
    div []
        [
         h3 [] [text "Percepts"]
        , table [classList [("table", True), ("table-bordered", True)]]
                  [
                   tbody []
                           (List.map (viewPercept address model.percepts) (Dict.keys model.percepts |> List.sort))
                  ]
        ]

