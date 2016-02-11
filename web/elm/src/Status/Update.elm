module Status.Update where

import Json.Decode as Json exposing ((:=))
import RobotConfig exposing (hostname)
import String.Interpolate exposing(interpolate)
import Http
import Effects exposing (Effects)
import Task exposing (Task, andThen)
import Status.Model as Model exposing (Model, RuntimeStats, ActiveState)

type Action =
  NoOp (Maybe String)
    | SetPaused (Maybe Bool)
    | SwitchPaused
    | SetActive ActiveState
    | TogglePaused
    | SetRuntimeStats RuntimeStats

init: (Model, Effects Action)
init =
  (Model.initialModel, fetchPaused)

update: Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SetPaused maybePaused ->
      let
        result =
          Maybe.withDefault model.paused maybePaused
      in
      ({model | paused = result}, Effects.none)
    SwitchPaused ->
      ({model | paused = not model.paused}, Effects.none)
    SetActive activeState ->
      ({model | active = activeState.active}, Effects.none)
    TogglePaused ->
      (model, togglePaused)
    SetRuntimeStats runtimeStats ->
      ({model | runtime = runtimeStats}, Effects.none)
    _ ->
      (model, Effects.none)

-- EFFECTS

togglePaused: Effects Action 
togglePaused =
  let
    togglePausedEffect = (Http.post Json.string (interpolate "http://{0}:4000/api/robot/togglePaused" [hostname]) Http.empty
                |> Task.toMaybe
                |> Task.map NoOp
                |> Effects.task)
  in
    Effects.batch [togglePausedEffect, switchPaused]

fetchPaused: Effects Action
fetchPaused =
  Http.get decodePaused (interpolate "http://{0}:4000/api/robot/paused" [hostname])
      |> Task.toMaybe
      |> Task.map SetPaused
      |> Effects.task

switchPaused: Effects Action
switchPaused =
  Task.succeed SwitchPaused
  |> Effects.task

decodePaused: Json.Decoder Bool
decodePaused =
  "paused" := Json.bool

