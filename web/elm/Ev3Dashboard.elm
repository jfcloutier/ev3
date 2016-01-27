module Ev3Dashboard where

import Html exposing (..)
import StartApp
import Html.Events exposing (onClick)
import Effects exposing (Effects, Never)
import Task exposing (Task, andThen)
import Http
import Json.Decode as Json exposing ((:=))
import String.Interpolate exposing(interpolate)

type Action = NoOp (Maybe String) | SetPaused (Maybe Bool) | TogglePaused | SetRuntimeStats RuntimeStats

type alias RuntimeStats = {ramFree: Int, ramUsed: Int, swapFree: Int, swapUsed: Int}
                   
type alias Model = {paused : Bool,
                    runtime : RuntimeStats
                   }

app : StartApp.App Model
app =
  StartApp.start
          {init = init
           , update = update
           , view = view
           , inputs = [incomingRuntimeStats]
          }

main : Signal Html
main =
  app.html

init : (Model, Effects Action)
init =
  let
    status = Model False {ramFree = -1, ramUsed = -1, swapFree = -1, swapUsed = -1}
  in
    (status, fetchPaused)

hostname : String
hostname =
  "localhost"
--  "192.168.1.136"
 
-- UPDATE

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NoOp _ ->
      (model, Effects.none)
    SetPaused maybePaused ->
      let
        result =
          Maybe.withDefault model.paused maybePaused
      in
      ({model | paused = result}, Effects.none)
    TogglePaused ->
      (model, togglePaused)
    SetRuntimeStats runtimeStats ->
      ({model | runtime = runtimeStats}, Effects.none)

-- VIEW
    
view : Signal.Address Action -> Model -> Html
view address model =
  let
    pausingLabel model =
      if not model.paused then
        "Pause"
      else
        "Resume"
  in
    div []
        [
         div []
             [div []
               [span [] [text "Paused: "]
                , span [] [text (toString model.paused)]
                , div []
                  [span [] [text "RAM free="]
                   , span [] [text (toString model.runtime.ramFree)]
                  , span [] [text " RAM used="]
                  , span [] [text (toString model.runtime.ramUsed)]
                  , span [] [text " Swap free="]
                  , span [] [text (toString model.runtime.swapFree)]
                  , span [] [text " Swap used="]
                  , span [] [text (toString model.runtime.swapUsed)]
                  ]
               ]
              ]
         , button [onClick address TogglePaused]
                [text (pausingLabel model)]
        ]

-- EFFECTS


togglePaused: Effects Action
togglePaused =
  let
    togglePausedEffect = (Http.post Json.string (interpolate "http://{0}:4000/api/robot/togglePaused" [hostname]) Http.empty
                |> Task.toMaybe
                |> Task.map NoOp
                |> Effects.task)
  in
    Effects.batch [togglePausedEffect, fetchPaused]

fetchPaused : Effects Action
fetchPaused =
  Http.get decodePaused (interpolate "http://{0}:4000/api/robot/paused" [hostname])
      |> Task.toMaybe
      |> Task.map SetPaused  
      |> Effects.task

decodePaused: Json.Decoder Bool
decodePaused =
  "paused" := Json.bool

-- PORTS

port tasks : Signal (Task Never ())
port tasks =
  app.tasks -- From effects

port runtimeStats : Signal RuntimeStats -- From channels

-- SIGNALS IN FROM CHANNELS
                    
incomingRuntimeStats: Signal Action
incomingRuntimeStats = Signal.map SetRuntimeStats runtimeStats
