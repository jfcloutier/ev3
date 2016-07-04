module Motivation.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, attribute, classList)
import Motivation.Model as Model exposing (Model)
import Motivation.Update exposing (Msg)
import Dict exposing (Dict)

view: Model -> Html Msg
view model =
  let
    getMotive about motives =
      Dict.get about motives |> Maybe.withDefault Model.defaultMotive
    isOn about motives =
        (getMotive about motives).on
    isInhibited about motives =
      (getMotive about motives).inhibited
    onOffClass bool =
               if bool then
                 "bg-success"
               else
                 "bg-danger"
    inhibitedText bool about =
      if bool then
        node "s" [] [text about]
      else
        text about
    viewMotive address motives about =
      tr []
         [
          td [] [
                 strong [class (onOffClass (isOn about motives))] [inhibitedText (isInhibited about motives) about]
                ]
         ]
  in
    div []
        [
         h3 [] [text "Motives"]
         ,  table [classList [("table", True), ("table-bordered", True)]]
                  [
                   tbody []
                           (List.map (viewMotive address model.motives) (Dict.keys model.motives |> List.sort))
                  ] 
         ]
