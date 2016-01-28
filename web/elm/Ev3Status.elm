module Ev3Status (StatusAction(Status),
                  Action(SetRuntimeStats),
                  RuntimeStats,
                  Model,
                  initModel,
                  initEffect,
                  update,
                  view) where

import Html exposing (..)
import StartApp
import Html.Events exposing (onClick)
import Html.Attributes exposing (class, classList)
import Effects exposing (Effects, Never)
import Task exposing (Task, andThen)
import Http
import Json.Decode as Json exposing ((:=))
import String.Interpolate exposing(interpolate)

import Ev3Utils exposing(hostname)

type Action = NoOp (Maybe String)
            | SetPaused (Maybe Bool)
            | TogglePaused
            | SetRuntimeStats RuntimeStats

type StatusAction = Status Action

type alias RuntimeStats = {ramFree: Int, ramUsed: Int, swapFree: Int, swapUsed: Int}
                   
type alias Model = {paused : Bool,
                    runtime : RuntimeStats
                   }


-- MODEL

initModel: Model
initModel =
   Model False {ramFree = -1, ramUsed = -1, swapFree = -1, swapUsed = -1}

initEffect: Effects StatusAction
initEffect =
  fetchPaused

-- UPDATE

update : Action -> Model -> (Model, Effects StatusAction)
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
    
view : Signal.Address StatusAction -> Model -> Html
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
  in
    div [class "container"]
          [
           div [class "row"]
                 [
                  div [class "col-md-12"] [
                          button [onClick address (Status TogglePaused), classList [ ("btn", True), ((btnColor model.paused), True)]] [text (pausingLabel model)]
                         ]
                 ]
          , div [class "row"]
                  [
                   div [class "col-md-3"] [text "RAM free"]
                  , div [class "col-md-3"] [text " RAM used"]
                  , div [class "col-md-3"] [text " Swap free"]
                  , div [class "col-md-3"] [text " Swap used"]
                  ]
          , div [class "row"]
                  [
                   div [class "col-md-3"] [text (toString model.runtime.ramFree)]
                  , div [class "col-md-3"] [text (toString model.runtime.ramUsed)]
                  , div [class "col-md-3"] [text (toString model.runtime.swapFree)]
                  , div [class "col-md-3"] [text (toString model.runtime.swapUsed)]
                  ]
          ] 

-- EFFECTS

togglePaused: Effects StatusAction
togglePaused =
  let
    togglePausedEffect = (Http.post Json.string (interpolate "http://{0}:4000/api/robot/togglePaused" [hostname]) Http.empty
                |> Task.toMaybe
                |> Task.map NoOp
                |> Task.map Status
                |> Effects.task)
  in
    Effects.batch [togglePausedEffect, fetchPaused]

fetchPaused : Effects StatusAction
fetchPaused =
  Http.get decodePaused (interpolate "http://{0}:4000/api/robot/paused" [hostname])
      |> Task.toMaybe
      |> Task.map SetPaused
      |> Task.map Status
      |> Effects.task

decodePaused: Json.Decoder Bool
decodePaused =
  "paused" := Json.bool
