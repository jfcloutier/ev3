module Ev3Dashboard where

import Html exposing (..)
import StartApp
import Html.Attributes exposing (class, attribute, classList)
import Html.Events exposing (onClick)
import Effects exposing (Effects, Never)
import List exposing (concat)
import Task exposing (Task, andThen)
import Http
import Json.Decode as Json exposing ((:=))
import String.Interpolate exposing(interpolate)
import Dict exposing (Dict)

type Action =
  NoOp (Maybe String)
    | SetPaused (Maybe Bool)
    | SetActive ActiveState
    | TogglePaused
    | SetRuntimeStats RuntimeStats
    | AddPercept Percept
    | SetMotive Motive

type alias StatusModel = {paused : Bool,
                    active: Bool,
                    runtime : RuntimeStats
                   }

type alias PerceptionModel = {percepts: Dict String String}
type alias Percept = {about: String, value: String}

type alias MotivationModel = {motives: Dict String Motive}                   
type alias Motive = {about: String, on: Bool, inhibited: Bool}

type alias Model = {status: StatusModel
                   , perception: PerceptionModel
                   , motivation: MotivationModel
                   }
type alias ActiveState = {active: Bool}
type alias RuntimeStats = {ramFree: Int, ramUsed: Int, swapFree: Int, swapUsed: Int}

                        
hostname : String
hostname =
  "localhost"
--  "192.168.1.136"

app : StartApp.App Model
app =
  StartApp.start
          {init = init
           , update = update
           , view = view
           , inputs = inputs
          }

main : Signal Html
main =
  app.html

-- MODEL

init: (Model, Effects Action)
init =
  ({status = statusInitModel
    , perception = perceptionInitModel
    , motivation = motivationInitModel
   },
   Effects.batch([statusInitEffect, perceptionInitEffect, motivationInitEffect]))

statusInitModel: StatusModel
statusInitModel =
  StatusModel False True {ramFree = -1, ramUsed = -1, swapFree = -1, swapUsed = -1}

perceptionInitModel: PerceptionModel
perceptionInitModel =
  {percepts = Dict.empty}

motivationInitModel: MotivationModel
motivationInitModel =
  {motives = Dict.empty}
  
statusInitEffect: Effects Action
statusInitEffect =
  fetchPaused

perceptionInitEffect: Effects Action
perceptionInitEffect = Effects.none

motivationInitEffect: Effects Action
motivationInitEffect = Effects.none


-- VIEW

view: Signal.Address Action -> Model -> Html
view address model =
  div[class "container-fluid", attribute "role" "main"]
       [  h1 [class "text-center"] [text "Robot Dashboard"]
       , div [class "row"]
               [
                div [class "col-md-12"] [statusView address model.status]
               ]
       , div [class "row"]
               [
                div [class "col-md-3"] [perceptionView address model.perception]
               , div [class "col-md-1"] [motivationView address model.motivation]
               ]
       ]
       
statusView: Signal.Address Action -> StatusModel -> Html
statusView address model =
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
      over value threshold =
        if value < threshold then
          "danger"
        else
          "success"
      src active =
        if active then
          "/images/active.png"
        else
          "/images/fainted.png"
    in
      div [class "container"]
          [
      div [class "row"]
                   [
                    div [class "col-md-2"]
                          [
                           button
                           [onClick address TogglePaused
                           , classList [ ("btn", True), ((btnColor model.paused), True)]]
                           [text (pausingLabel model)]
                          ]
                   , div [class "col-md-2"]
                           [
                            img [attribute "src" (src model.active)] []
                           ]
                   , div [class "col-md-8"]
                           [
                            table [classList [("table", True), ("table-bordered", True)]]
                                    [
                                     thead []
                                             [
                                              th [] [text "RAM free (M)"]
                                             , th [] [text " RAM used (M)"]
                                             , th [] [text " Swap free (M)"]
                                             , th [] [text " Swap used (M)"]
                                             ]
                                    , tbody []
                                              [
                                               tr []
                                                    [
                                                     td [class (over model.runtime.ramFree 10)] [text (toString model.runtime.ramFree)]
                                                    , td [] [text (toString model.runtime.ramUsed)]
                                                    , td [class (over model.runtime.swapFree 10)] [text (toString model.runtime.swapFree)]
                                                    , td [] [text (toString model.runtime.swapUsed)]
                                                    ]
                                              ]
                                    ]
                           ]  
                   ]
    ]

      
perceptionView: Signal.Address Action -> PerceptionModel -> Html
perceptionView address model =
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
         h2 [] [text "Percepts"]
        , table [classList [("table", True), ("table-bordered", True)]]
                  [
                   tbody []
                           (List.map (viewPercept address model.percepts) (Dict.keys model.percepts |> List.sort))
                  ]
        ]

motivationView: Signal.Address Action -> MotivationModel -> Html
motivationView address model =
  let
    getMotive about motives =
      Dict.get about motives |> Maybe.withDefault (Motive "" False False)
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
         h2 [] [text "Motives"]
         ,  table [classList [("table", True), ("table-bordered", True)]]
                  [
                   tbody []
                           (List.map (viewMotive address model.motives) (Dict.keys model.motives |> List.sort))
                  ] 
         ]

-- UPDATE

update : Action -> Model -> (Model, Effects Action)
update action model =
  let
    (newStatus, statusEffects) = statusUpdate action model.status
    (newPerception, perceptionEffects) = perceptionUpdate action model.perception
    (newMotivation, motivationEffects) = motivationUpdate action model.motivation
  in
    (
     { model | status = newStatus, perception = newPerception, motivation = newMotivation},
     Effects.batch[statusEffects, perceptionEffects, motivationEffects]
    )
  
  
statusUpdate: Action -> StatusModel -> (StatusModel, Effects Action)
statusUpdate action model =
  case action of
    SetPaused maybePaused ->
      let
        result =
          Maybe.withDefault model.paused maybePaused
      in
      ({model | paused = result}, Effects.none)
    SetActive activeState ->
      ({model | active = activeState.active}, Effects.none)
    TogglePaused ->
      (model, togglePaused)
    SetRuntimeStats runtimeStats ->
      ({model | runtime = runtimeStats}, Effects.none)
    _ ->
      (model, Effects.none)

perceptionUpdate: Action -> PerceptionModel -> (PerceptionModel, Effects Action)
perceptionUpdate action model =
  case action of
    AddPercept percept ->
      ({model | percepts = Dict.insert percept.about percept.value model.percepts}, Effects.none)
    _ ->
      (model, Effects.none)

motivationUpdate: Action -> MotivationModel -> (MotivationModel, Effects Action)
motivationUpdate action model =
  case action of
    SetMotive motive ->
      ({model | motives = Dict.insert motive.about motive model.motives}, Effects.none)
    _ ->
      (model, Effects.none)

-- EFFECTS

-- status

togglePaused: Effects Action
togglePaused =
  let
    togglePausedEffect = (Http.post Json.string (interpolate "http://{0}:4000/api/robot/togglePaused" [hostname]) Http.empty
                |> Task.toMaybe
                |> Task.map NoOp
                |> Effects.task)
  in
    Effects.batch [togglePausedEffect, fetchPaused]

fetchPaused: Effects Action
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

-- status
port runtimeStatsPort : Signal RuntimeStats
port activeStatePort : Signal ActiveState

-- perception
port perceptPort : Signal Percept

-- motivation
port motivePort : Signal Motive
-- INPUTS

inputs: List (Signal Action)
inputs =
  concat [statusInputs, perceptionInputs, motivationInputs]

-- status
statusInputs: List(Signal Action)
statusInputs =
  [Signal.map SetRuntimeStats runtimeStatsPort
   , Signal.map SetActive activeStatePort
  ]

-- perception
perceptionInputs: List(Signal Action)
perceptionInputs =
  [Signal.map AddPercept perceptPort]

-- motivation
motivationInputs: List(Signal Action)
motivationInputs =
  [Signal.map SetMotive motivePort]
