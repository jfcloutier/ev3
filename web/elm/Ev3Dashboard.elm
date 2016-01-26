module Ev3Dashboard where

import Html exposing (..)
import StartApp
import Html.Events exposing (onClick)
import Effects exposing (Effects, Never)
import Task exposing (Task, andThen)
import Http
import Json.Decode as Json exposing ((:=))

type Action = NoOp (Maybe String) | SetPaused (Maybe Model) | TogglePaused

type alias Model = {paused : Bool}

app : StartApp.App Model
app =
  StartApp.start
          {init = init
           , update = update
           , view = view
           , inputs = []
          }

main : Signal Html
main =
  app.html

port tasks: Signal (Task Never ())
port tasks =
  app.tasks

init : (Model, Effects Action)
init =
  let
    status = Model False
  in
    (status, fetchPaused)

-- UPDATE

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NoOp _ ->
      (model, Effects.none)
    SetPaused maybePaused ->
      (Maybe.withDefault (Model False) maybePaused, Effects.none)
    TogglePaused ->
      (model, togglePaused)

-- VIEW
    
view : Signal.Address Action -> Model -> Html
view address model =
  let
    changeTo model =
      if not model.paused then
        "Pause"
      else
        "Resume"
  in
    div []
        [
         div []
               [span [] [text "Paused: "]
                , span [] [text (toString model.paused)]
               ]
         , button [onClick address TogglePaused]
                [text (changeTo model)]
        ]

-- EFFECTS


togglePaused: Effects Action
togglePaused =
  let
    toggleEffect = (Http.post Json.string "http://localhost:4000/api/robot/togglePaused" Http.empty
                |> Task.toMaybe
                |> Task.map NoOp
                |> Effects.task)
  in
    Effects.batch [toggleEffect, fetchPaused]

fetchPaused : Effects Action
fetchPaused =
  Http.get decodePaused "http://localhost:4000/api/robot/paused"
      |> Task.toMaybe
      |> Task.map SetPaused  
      |> Effects.task

decodePaused: Json.Decoder Model
decodePaused =
  Json.object1 Model ("paused" := Json.bool)
  


  
