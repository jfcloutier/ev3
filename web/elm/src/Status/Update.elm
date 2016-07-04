module Status.Update exposing (..)

import Json.Decode as Json exposing ((:=))
import RobotConfig exposing (hostname)
import Http exposing (..)
import Task
import Status.Model as Model exposing (Model, RuntimeStats, ActiveState)
import Update.Extra.Infix exposing ((:>))

type Msg =
  NoOp (Maybe String)
    | SetPaused (Maybe Bool)
    | SetActive ActiveState
    | TogglePaused
    | HTTPCallFailed Http.Error
    | TogglePauseRequested String
    | PausedFetched Bool
    | SetRuntimeStats RuntimeStats

init: (Model, Cmd Msg)
init =
  (Model.initialModel, fetchPaused)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SetPaused maybePauseRequested ->
      let
        result =
          Maybe.withDefault model.pauseRequested maybePauseRequested
      in
      ({model | pauseRequested = result}, Cmd.none)
    SetActive activeState ->
      ({model | active = activeState.active}, Cmd.none)
    TogglePaused ->
      (model, togglePaused)
    HTTPCallFailed error ->
      (model, Cmd.none)
    TogglePauseRequested string ->
      (model, fetchPaused)
    PausedFetched bool -> -- NEEDED?
      model ! [] :> update (SetPaused (Just bool))
    SetRuntimeStats runtimeStats ->
      ({model | runtime = runtimeStats}, Cmd.none)
    _ ->
      (model, Cmd.none)

-- EFFECTS

togglePaused: Cmd Msg 
togglePaused =
  let
    url = "http://" ++ hostname ++ ":4000/api/robot/togglePaused"
  in
      Task.perform HTTPCallFailed TogglePauseRequested (Http.post Json.string url empty)
          
fetchPaused: Cmd Msg
fetchPaused =
  let
    url =
      "http://" ++ hostname ++ ":4000/api/robot/paused"

    decodePaused =
      "paused" := Json.bool
  in
    Task.perform HTTPCallFailed PausedFetched (Http.get decodePaused url)

