module App.Update where

import Effects exposing (Effects)
import App.Model as Model exposing (Model)
import Status.Update
import Perception.Update
import Motivation.Update
import Comportment.Update
import Actuation.Update

type Action =
  StatusAction Status.Update.Action
    | PerceptionAction Perception.Update.Action
    | MotivationAction Motivation.Update.Action
    | ComportmentAction Comportment.Update.Action
    | ActuationAction Actuation.Update.Action

initialEffects: List (Effects Action)
initialEffects =
  [Effects.map StatusAction <| snd Status.Update.init]
      
init: (Model, Effects Action)
init =
  (Model.initialModel
      , Effects.batch initialEffects)

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
       StatusAction statusAction ->
         let
           (newStatus, statusEffects) = Status.Update.update statusAction model.status
         in
           ({model | status = newStatus}, Effects.map StatusAction statusEffects)
       PerceptionAction perceptionAction ->
         let
           (newPerception, perceptionEffects) = Perception.Update.update perceptionAction model.perception
         in
           ({model | perception = newPerception}, Effects.map PerceptionAction perceptionEffects)
       MotivationAction motivationAction ->
         let
           (newMotivation, motivationEffects) = Motivation.Update.update motivationAction model.motivation
         in
           ({model | motivation = newMotivation}, Effects.map MotivationAction motivationEffects)
       ComportmentAction comportmentAction ->
         let
           (newComportment, comportmentEffects) = Comportment.Update.update comportmentAction model.comportment
         in
           ({model | comportment = newComportment}, Effects.map ComportmentAction comportmentEffects)
       ActuationAction actuationAction ->
         let
           (newActuation, actuationEffects) = Actuation.Update.update actuationAction model.actuation
         in
           ({model | actuation = newActuation}, Effects.map ActuationAction actuationEffects)

