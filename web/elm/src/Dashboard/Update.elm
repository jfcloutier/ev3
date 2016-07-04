module Dashboard.Update exposing (..)

import Dashboard.Model as Model exposing (Model)
import Status.Update
import Perception.Update
import Motivation.Update
import Comportment.Update
import Actuation.Update

type Msg =
  StatusMsg Status.Update.Msg
    | PerceptionMsg Perception.Update.Msg
    | MotivationMsg Motivation.Update.Msg
    | ComportmentMsg Comportment.Update.Msg
    | ActuationMsg Actuation.Update.Msg

initialCmds: List (Cmd Msg)
initialCmds =
  [Cmd.map StatusMsg <| snd Status.Update.init]
      
init: (Model, Cmd Msg)
init =
  (Model.initialModel
      , Cmd.batch initialCmds)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
       StatusMsg statusMsg ->
         let
           (newStatus, statusCmd) = Status.Update.update statusMsg model.status
         in
           ({model | status = newStatus}, Cmd.map StatusMsg statusCmd)
       PerceptionMsg perceptionMsg ->
         let
           (newPerception, perceptionCmd) = Perception.Update.update perceptionMsg model.perception
         in
           ({model | perception = newPerception}, Cmd.map PerceptionMsg perceptionCmd)
       MotivationMsg motivationMsg ->
         let
           (newMotivation, motivationCmd) = Motivation.Update.update motivationMsg model.motivation
         in
           ({model | motivation = newMotivation}, Cmd.map MotivationMsg motivationCmd)
       ComportmentMsg comportmentMsg ->
         let
           (newComportment, comportmentCmd) = Comportment.Update.update comportmentMsg model.comportment
         in
           ({model | comportment = newComportment}, Cmd.map ComportmentMsg comportmentCmd)
       ActuationMsg actuationMsg ->
         let
           (newActuation, actuationCmd) = Actuation.Update.update actuationMsg model.actuation
         in
           ({model | actuation = newActuation}, Cmd.map ActuationMsg actuationCmd)

